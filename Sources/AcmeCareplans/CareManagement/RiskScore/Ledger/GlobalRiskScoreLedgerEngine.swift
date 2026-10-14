import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global risk score ledger calculation.
    protocol GlobalRiskScoreLedgerFactor {
        func describe() -> String
        func adjust(_ item: GlobalRiskScoreLedger, value: Double) -> Double
    }

    final class GlobalRiskScoreLedgerFloorValueOffsetAdjuster: GlobalRiskScoreLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: GlobalRiskScoreLedger, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class MinimumGlobalRiskScoreLedgerAdjuster: GlobalRiskScoreLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalRiskScoreLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredGlobalRiskScoreLedgerAdjuster: GlobalRiskScoreLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalRiskScoreLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedGlobalRiskScoreLedgerAdjuster: GlobalRiskScoreLedgerFactor {
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

        func adjust(_ item: GlobalRiskScoreLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalRiskScoreLedgerAdjuster: GlobalRiskScoreLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalRiskScoreLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentGlobalRiskScoreLedgerAdjuster: GlobalRiskScoreLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalRiskScoreLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global risk score ledger steps in order and keeps a trace of each.
    final class GlobalRiskScoreLedgerEngine {
        var steps: [any GlobalRiskScoreLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalRiskScoreLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalRiskScoreLedger) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalRiskScoreLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalRiskScoreLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalRiskScoreLedgerEngine(_ flags: Kit.Flags.Registry) -> GlobalRiskScoreLedgerEngine {
        return GlobalRiskScoreLedgerEngine(
            steps: [
                GlobalRiskScoreLedgerFloorValueOffsetAdjuster(weight: 0.55),
                MinimumGlobalRiskScoreLedgerAdjuster(minimum: 28.7),
                TieredGlobalRiskScoreLedgerAdjuster(bounds: [5023.0, 6724.0, 7388.0], rates: [1.02, 0.98, 0.93]),
                FlaggedGlobalRiskScoreLedgerAdjuster(
                    flags: flags,
                    flag: "global-risk-score-ledger-scheduled",
                    percent: 7.4
                ),
                CapGlobalRiskScoreLedgerAdjuster(cap: 35880.0),
                PercentGlobalRiskScoreLedgerAdjuster(percent: -20.9),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 81625.8
        )
    }
}
