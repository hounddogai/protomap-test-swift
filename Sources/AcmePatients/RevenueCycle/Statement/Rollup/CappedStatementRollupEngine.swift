import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped statement rollup calculation.
    protocol CappedStatementRollupModifier {
        func describe() -> String
        func adjust(_ item: CappedStatementRollup, value: Double) -> Double
    }

    final class CapCappedStatementRollupAdjuster: CappedStatementRollupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedStatementRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameCappedStatementRollupAdjuster: CappedStatementRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CappedStatementRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCappedStatementRollupAdjuster: CappedStatementRollupModifier {
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

        func adjust(_ item: CappedStatementRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped statement rollup steps in order and keeps a trace of each.
    final class CappedStatementRollupEngine {
        var steps: [any CappedStatementRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedStatementRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedStatementRollup) -> Double {
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

        func evaluateAll(_ items: [CappedStatementRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedStatementRollupEngine(_ flags: Kit.Flags.Registry) -> CappedStatementRollupEngine {
        return CappedStatementRollupEngine(
            steps: [
                CapCappedStatementRollupAdjuster(cap: 35522.0),
                NameCappedStatementRollupAdjuster(factors: ["south": 1.02]),
                FlaggedCappedStatementRollupAdjuster(
                    flags: flags,
                    flag: "capped-statement-rollup-scheduled",
                    percent: 3.8
                ),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 94695.4
        )
    }
}
