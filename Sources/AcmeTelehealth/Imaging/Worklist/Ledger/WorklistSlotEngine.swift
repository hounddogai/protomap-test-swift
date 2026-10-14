import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist slot calculation.
    protocol WorklistSlotFactor {
        func describe() -> String
        func adjust(_ item: WorklistSlot, value: Double) -> Double
    }

    final class PercentWorklistSlotAdjuster: WorklistSlotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWorklistSlotAdjuster: WorklistSlotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapWorklistSlotAdjuster: WorklistSlotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WorklistSlotCapacityOffsetAdjuster: WorklistSlotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: WorklistSlot, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the worklist slot steps in order and keeps a trace of each.
    final class WorklistSlotEngine {
        var steps: [any WorklistSlotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistSlotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WorklistSlot) -> Double {
            var current = item.projectedExposure()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [WorklistSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWorklistSlotEngine() -> WorklistSlotEngine {
        return WorklistSlotEngine(
            steps: [
                PercentWorklistSlotAdjuster(percent: 18.8),
                TieredWorklistSlotAdjuster(bounds: [2671.0, 4930.0], rates: [0.81, 0.98]),
                CapWorklistSlotAdjuster(cap: 17220.0),
                WorklistSlotCapacityOffsetAdjuster(weight: 1.5),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 65408.7
        )
    }
}
