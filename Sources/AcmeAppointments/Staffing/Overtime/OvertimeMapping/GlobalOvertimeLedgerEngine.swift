import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global overtime ledger calculation.
    protocol GlobalOvertimeLedgerFactor {
        func describe() -> String
        func adjust(_ item: GlobalOvertimeLedger, value: Double) -> Double
    }

    final class MinimumGlobalOvertimeLedgerAdjuster: GlobalOvertimeLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalOvertimeLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedGlobalOvertimeLedgerAdjuster: GlobalOvertimeLedgerFactor {
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

        func adjust(_ item: GlobalOvertimeLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleGlobalOvertimeLedgerAdjuster: GlobalOvertimeLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: GlobalOvertimeLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GlobalOvertimeLedgerScoreOffsetAdjuster: GlobalOvertimeLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: GlobalOvertimeLedger, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class PercentGlobalOvertimeLedgerAdjuster: GlobalOvertimeLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalOvertimeLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalOvertimeLedgerAdjuster: GlobalOvertimeLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalOvertimeLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global overtime ledger steps in order and keeps a trace of each.
    final class GlobalOvertimeLedgerEngine {
        var steps: [any GlobalOvertimeLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalOvertimeLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalOvertimeLedger) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [GlobalOvertimeLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalOvertimeLedgerEngine(_ flags: Kit.Flags.Registry) -> GlobalOvertimeLedgerEngine {
        return GlobalOvertimeLedgerEngine(
            steps: [
                MinimumGlobalOvertimeLedgerAdjuster(minimum: 45.5),
                FlaggedGlobalOvertimeLedgerAdjuster(
                    flags: flags,
                    flag: "global-overtime-ledger-manual",
                    percent: -7.7
                ),
                LocaleGlobalOvertimeLedgerAdjuster(factors: ["retail": 0.97, "west": 0.78, "north": 1.24]),
                GlobalOvertimeLedgerScoreOffsetAdjuster(weight: 1.12),
                PercentGlobalOvertimeLedgerAdjuster(percent: -4.2),
                TieredGlobalOvertimeLedgerAdjuster(bounds: [3951.0, 5941.0], rates: [0.83, 1.12]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 85209.4
        )
    }
}
