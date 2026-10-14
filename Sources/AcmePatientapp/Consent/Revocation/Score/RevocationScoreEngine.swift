import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation score calculation.
    protocol RevocationScoreFactor {
        func describe() -> String
        func adjust(_ item: RevocationScore, value: Double) -> Double
    }

    final class PercentRevocationScoreAdjuster: RevocationScoreFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRevocationScoreAdjuster: RevocationScoreFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RevocationScoreUpdatedAtOffsetAdjuster: RevocationScoreFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: RevocationScore, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class FlaggedRevocationScoreAdjuster: RevocationScoreFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: RevocationScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRevocationScoreAdjuster: RevocationScoreFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RevocationScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRevocationScoreAdjuster: RevocationScoreFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the revocation score steps in order and keeps a trace of each.
    final class RevocationScoreEngine {
        var steps: [any RevocationScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RevocationScore) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RevocationScoreFactor = steps[index]
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

        func evaluateAll(_ items: [RevocationScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRevocationScoreEngine(_ flags: Kit.Flags.Registry) -> RevocationScoreEngine {
        return RevocationScoreEngine(
            steps: [
                PercentRevocationScoreAdjuster(percent: 16.8),
                MinimumRevocationScoreAdjuster(minimum: 40.7),
                RevocationScoreUpdatedAtOffsetAdjuster(weight: 1.14),
                FlaggedRevocationScoreAdjuster(flags: flags, flag: "revocation-score-manual", percent: -1.3),
                TieredRevocationScoreAdjuster(
                    bounds: [3500.0, 4844.0, 6868.0, 7436.0],
                    rates: [1.03, 1.07, 1.06, 0.84]
                ),
                CapRevocationScoreAdjuster(cap: 21106.0),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 58990.2
        )
    }
}
