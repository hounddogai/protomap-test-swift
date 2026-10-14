import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance digest calculation.
    protocol RemittanceDigestAdjuster {
        func describe() -> String
        func adjust(_ item: RemittanceDigest, value: Double) -> Double
    }

    final class CapRemittanceDigestAdjuster: RemittanceDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRemittanceDigestAdjuster: RemittanceDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRemittanceDigestAdjuster: RemittanceDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRemittanceDigestAdjuster: RemittanceDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the remittance digest steps in order and keeps a trace of each.
    final class RemittanceDigestEngine {
        var steps: [any RemittanceDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RemittanceDigest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [RemittanceDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRemittanceDigestEngine() -> RemittanceDigestEngine {
        return RemittanceDigestEngine(
            steps: [
                CapRemittanceDigestAdjuster(cap: 47777.0),
                PercentRemittanceDigestAdjuster(percent: 14.7),
                RoundingRemittanceDigestAdjuster(step: 0.05),
                MinimumRemittanceDigestAdjuster(minimum: 19.9),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 58172.1
        )
    }
}
