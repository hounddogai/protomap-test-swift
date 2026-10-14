import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered priority schedule calculation.
    protocol TieredPriorityScheduleFactor {
        func describe() -> String
        func adjust(_ item: TieredPrioritySchedule, value: Double) -> Double
    }

    final class TieredTieredPriorityScheduleAdjuster: TieredPriorityScheduleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredPrioritySchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TieredPriorityScheduleRevisionOffsetAdjuster: TieredPriorityScheduleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: TieredPrioritySchedule, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class CapTieredPriorityScheduleAdjuster: TieredPriorityScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredPrioritySchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered priority schedule steps in order and keeps a trace of each.
    final class TieredPriorityScheduleEngine {
        var steps: [any TieredPriorityScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredPriorityScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredPrioritySchedule) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [TieredPrioritySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredPriorityScheduleEngine() -> TieredPriorityScheduleEngine {
        return TieredPriorityScheduleEngine(
            steps: [
                TieredTieredPriorityScheduleAdjuster(bounds: [2498.0, 9276.0], rates: [0.97, 0.99]),
                TieredPriorityScheduleRevisionOffsetAdjuster(weight: 0.96),
                CapTieredPriorityScheduleAdjuster(cap: 5113.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 41465.2
        )
    }
}
