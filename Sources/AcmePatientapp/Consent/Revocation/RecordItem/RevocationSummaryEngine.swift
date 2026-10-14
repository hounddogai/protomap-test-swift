import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation summary calculation.
    protocol RevocationSummaryStep {
        func describe() -> String
        func adjust(_ item: RevocationSummary, value: Double) -> Double
    }

    final class FlaggedRevocationSummaryAdjuster: RevocationSummaryStep {
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

        func adjust(_ item: RevocationSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRevocationSummaryAdjuster: RevocationSummaryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RevocationSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRevocationSummaryAdjuster: RevocationSummaryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRevocationSummaryAdjuster: RevocationSummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRevocationSummaryAdjuster: RevocationSummaryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the revocation summary steps in order and keeps a trace of each.
    final class RevocationSummaryEngine {
        var steps: [any RevocationSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RevocationSummary) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [RevocationSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRevocationSummaryEngine(_ flags: Kit.Flags.Registry) -> RevocationSummaryEngine {
        return RevocationSummaryEngine(
            steps: [
                FlaggedRevocationSummaryAdjuster(flags: flags, flag: "revocation-summary-regional", percent: -5.9),
                TieredRevocationSummaryAdjuster(
                    bounds: [461.0, 1763.0, 2053.0, 2922.0],
                    rates: [1.03, 0.87, 0.81, 0.99]
                ),
                RoundingRevocationSummaryAdjuster(step: 0.25),
                PercentRevocationSummaryAdjuster(percent: 14.5),
                MinimumRevocationSummaryAdjuster(minimum: 44.4),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 82871.3
        )
    }
}
