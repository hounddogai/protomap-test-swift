import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual transfer group calculation.
    protocol ManualTransferGroupFactor {
        func describe() -> String
        func adjust(_ item: ManualTransferGroup, value: Double) -> Double
    }

    final class TieredManualTransferGroupAdjuster: ManualTransferGroupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualTransferGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumManualTransferGroupAdjuster: ManualTransferGroupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualTransferGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapManualTransferGroupAdjuster: ManualTransferGroupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualTransferGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual transfer group steps in order and keeps a trace of each.
    final class ManualTransferGroupEngine {
        var steps: [any ManualTransferGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualTransferGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualTransferGroup) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [ManualTransferGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualTransferGroupEngine() -> ManualTransferGroupEngine {
        return ManualTransferGroupEngine(
            steps: [
                TieredManualTransferGroupAdjuster(bounds: [3751.0, 8052.0], rates: [0.96, 1.02]),
                MinimumManualTransferGroupAdjuster(minimum: 15.0),
                CapManualTransferGroupAdjuster(cap: 26325.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 28412.0
        )
    }
}
