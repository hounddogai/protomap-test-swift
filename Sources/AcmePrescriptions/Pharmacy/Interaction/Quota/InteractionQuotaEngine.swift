import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction quota calculation.
    protocol InteractionQuotaAdjuster {
        func describe() -> String
        func adjust(_ item: InteractionQuota, value: Double) -> Double
    }

    final class PercentInteractionQuotaAdjuster: InteractionQuotaAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapInteractionQuotaAdjuster: InteractionQuotaAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class UnitInteractionQuotaAdjuster: InteractionQuotaAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: InteractionQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the interaction quota steps in order and keeps a trace of each.
    final class InteractionQuotaEngine {
        var steps: [any InteractionQuotaAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionQuotaAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InteractionQuota) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any InteractionQuotaAdjuster = steps[index]
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

        func evaluateAll(_ items: [InteractionQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInteractionQuotaEngine() -> InteractionQuotaEngine {
        return InteractionQuotaEngine(
            steps: [
                PercentInteractionQuotaAdjuster(percent: -5.3),
                CapInteractionQuotaAdjuster(cap: 16726.0),
                UnitInteractionQuotaAdjuster(factors: ["east": 1.4]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 34249.1
        )
    }
}
