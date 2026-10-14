import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score request calculation.
    protocol RiskScoreRequestFactor {
        func describe() -> String
        func adjust(_ item: RiskScoreRequest, value: Double) -> Double
    }

    final class MinimumRiskScoreRequestAdjuster: RiskScoreRequestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRiskScoreRequestAdjuster: RiskScoreRequestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRiskScoreRequestAdjuster: RiskScoreRequestFactor {
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

        func adjust(_ item: RiskScoreRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the risk score request steps in order and keeps a trace of each.
    final class RiskScoreRequestEngine {
        var steps: [any RiskScoreRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RiskScoreRequest) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreRequestFactor = steps[index]
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

        func evaluateAll(_ items: [RiskScoreRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRiskScoreRequestEngine(_ flags: Kit.Flags.Registry) -> RiskScoreRequestEngine {
        return RiskScoreRequestEngine(
            steps: [
                MinimumRiskScoreRequestAdjuster(minimum: 32.1),
                TieredRiskScoreRequestAdjuster(bounds: [3262.0, 6214.0], rates: [1.15, 1.18]),
                FlaggedRiskScoreRequestAdjuster(flags: flags, flag: "risk-score-request-weighted", percent: 9.8),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 66610.9
        )
    }
}
