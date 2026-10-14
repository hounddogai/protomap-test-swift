import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy formulary snapshot calculation.
    protocol LegacyFormularySnapshotStep {
        func describe() -> String
        func adjust(_ item: LegacyFormularySnapshot, value: Double) -> Double
    }

    final class FlaggedLegacyFormularySnapshotAdjuster: LegacyFormularySnapshotStep {
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

        func adjust(_ item: LegacyFormularySnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyFormularySnapshotAdjuster: LegacyFormularySnapshotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyFormularySnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLegacyFormularySnapshotAdjuster: LegacyFormularySnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyFormularySnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyFormularySnapshotAdjuster: LegacyFormularySnapshotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyFormularySnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceLegacyFormularySnapshotAdjuster: LegacyFormularySnapshotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: LegacyFormularySnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLegacyFormularySnapshotAdjuster: LegacyFormularySnapshotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyFormularySnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy formulary snapshot steps in order and keeps a trace of each.
    final class LegacyFormularySnapshotEngine {
        var steps: [any LegacyFormularySnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyFormularySnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyFormularySnapshot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyFormularySnapshotStep = steps[index]
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

        func evaluateAll(_ items: [LegacyFormularySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyFormularySnapshotEngine(_ flags: Kit.Flags.Registry) -> LegacyFormularySnapshotEngine {
        return LegacyFormularySnapshotEngine(
            steps: [
                FlaggedLegacyFormularySnapshotAdjuster(
                    flags: flags,
                    flag: "legacy-formulary-snapshot-tiered",
                    percent: -0.4
                ),
                RoundingLegacyFormularySnapshotAdjuster(step: 0.5),
                PercentLegacyFormularySnapshotAdjuster(percent: 2.7),
                CapLegacyFormularySnapshotAdjuster(cap: 13743.0),
                SourceLegacyFormularySnapshotAdjuster(factors: ["retail": 0.85]),
                TieredLegacyFormularySnapshotAdjuster(
                    bounds: [6359.0, 7864.0, 7945.0, 9498.0],
                    rates: [1.0, 1.07, 0.89, 1.02]
                ),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 52923.2
        )
    }
}
