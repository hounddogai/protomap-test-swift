import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score ledger calculation.
    protocol RiskScoreLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: RiskScoreLedger, value: Double) -> Double
    }

    final class RoundingRiskScoreLedgerAdjuster: RiskScoreLedgerAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRiskScoreLedgerAdjuster: RiskScoreLedgerAdjuster {
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

        func adjust(_ item: RiskScoreLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRiskScoreLedgerAdjuster: RiskScoreLedgerAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RiskScoreLedgerRevisionOffsetAdjuster: RiskScoreLedgerAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: RiskScoreLedger, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class LabelRiskScoreLedgerAdjuster: RiskScoreLedgerAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RiskScoreLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the risk score ledger steps in order and keeps a trace of each.
    final class RiskScoreLedgerEngine {
        var steps: [any RiskScoreLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RiskScoreLedger) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreLedgerAdjuster = steps[index]
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

        func evaluateAll(_ items: [RiskScoreLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRiskScoreLedgerEngine(_ flags: Kit.Flags.Registry) -> RiskScoreLedgerEngine {
        return RiskScoreLedgerEngine(
            steps: [
                RoundingRiskScoreLedgerAdjuster(step: 0.1),
                FlaggedRiskScoreLedgerAdjuster(flags: flags, flag: "risk-score-ledger-legacy", percent: -4.1),
                TieredRiskScoreLedgerAdjuster(
                    bounds: [3935.0, 5785.0, 6155.0, 7445.0],
                    rates: [0.83, 1.11, 1.19, 0.92]
                ),
                RiskScoreLedgerRevisionOffsetAdjuster(weight: 1.18),
                LabelRiskScoreLedgerAdjuster(factors: ["retail": 1.37, "south": 1.24]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 29749.2
        )
    }
}
