import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the global inventory group calculation.
    protocol GlobalInventoryGroupFactor {
        func describe() -> String
        func adjust(_ item: GlobalInventoryGroup, value: Double) -> Double
    }

    final class TieredGlobalInventoryGroupAdjuster: GlobalInventoryGroupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalInventoryGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalInventoryGroupAdjuster: GlobalInventoryGroupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalInventoryGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class GlobalInventoryGroupDosageMgOffsetAdjuster: GlobalInventoryGroupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: GlobalInventoryGroup, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    /// Runs the global inventory group steps in order and keeps a trace of each.
    final class GlobalInventoryGroupEngine {
        var steps: [any GlobalInventoryGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalInventoryGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalInventoryGroup) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [GlobalInventoryGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalInventoryGroupEngine() -> GlobalInventoryGroupEngine {
        return GlobalInventoryGroupEngine(
            steps: [
                TieredGlobalInventoryGroupAdjuster(bounds: [3357.0, 3949.0], rates: [0.9, 1.11]),
                PercentGlobalInventoryGroupAdjuster(percent: 22.6),
                GlobalInventoryGroupDosageMgOffsetAdjuster(weight: 1.19),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 4702.8
        )
    }
}
