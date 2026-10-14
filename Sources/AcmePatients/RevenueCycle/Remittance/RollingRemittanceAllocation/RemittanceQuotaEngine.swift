import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance quota calculation.
    protocol RemittanceQuotaStep {
        func describe() -> String
        func adjust(_ item: RemittanceQuota, value: Double) -> Double
    }

    final class CapRemittanceQuotaAdjuster: RemittanceQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RemittanceQuotaCapacityOffsetAdjuster: RemittanceQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: RemittanceQuota, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class MinimumRemittanceQuotaAdjuster: RemittanceQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the remittance quota steps in order and keeps a trace of each.
    final class RemittanceQuotaEngine {
        var steps: [any RemittanceQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RemittanceQuota) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceQuotaStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RemittanceQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRemittanceQuotaEngine() -> RemittanceQuotaEngine {
        return RemittanceQuotaEngine(
            steps: [
                CapRemittanceQuotaAdjuster(cap: 9228.0),
                RemittanceQuotaCapacityOffsetAdjuster(weight: 1.81),
                MinimumRemittanceQuotaAdjuster(minimum: 14.6),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 42267.4
        )
    }
}
