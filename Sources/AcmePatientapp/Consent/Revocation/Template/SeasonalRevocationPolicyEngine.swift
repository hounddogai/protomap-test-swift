import AcmePlatform
import Foundation

extension Consent {
    /// One step of the seasonal revocation policy calculation.
    protocol SeasonalRevocationPolicyFactor {
        func describe() -> String
        func adjust(_ item: SeasonalRevocationPolicy, value: Double) -> Double
    }

    final class RoundingSeasonalRevocationPolicyAdjuster: SeasonalRevocationPolicyFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalRevocationPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSeasonalRevocationPolicyAdjuster: SeasonalRevocationPolicyFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalRevocationPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSeasonalRevocationPolicyAdjuster: SeasonalRevocationPolicyFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalRevocationPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal revocation policy steps in order and keeps a trace of each.
    final class SeasonalRevocationPolicyEngine {
        var steps: [any SeasonalRevocationPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalRevocationPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalRevocationPolicy) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalRevocationPolicyFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalRevocationPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalRevocationPolicyEngine() -> SeasonalRevocationPolicyEngine {
        return SeasonalRevocationPolicyEngine(
            steps: [
                RoundingSeasonalRevocationPolicyAdjuster(step: 0.1),
                CapSeasonalRevocationPolicyAdjuster(cap: 48711.0),
                MinimumSeasonalRevocationPolicyAdjuster(minimum: 14.8),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 73977.2
        )
    }
}
