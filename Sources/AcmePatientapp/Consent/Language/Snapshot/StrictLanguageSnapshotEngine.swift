import AcmePlatform
import Foundation

extension Consent {
    /// One step of the strict language snapshot calculation.
    protocol StrictLanguageSnapshotStep {
        func describe() -> String
        func adjust(_ item: StrictLanguageSnapshot, value: Double) -> Double
    }

    final class FlaggedStrictLanguageSnapshotAdjuster: StrictLanguageSnapshotStep {
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

        func adjust(_ item: StrictLanguageSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentStrictLanguageSnapshotAdjuster: StrictLanguageSnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictLanguageSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictLanguageSnapshotAdjuster: StrictLanguageSnapshotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictLanguageSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict language snapshot steps in order and keeps a trace of each.
    final class StrictLanguageSnapshotEngine {
        var steps: [any StrictLanguageSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictLanguageSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictLanguageSnapshot) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [StrictLanguageSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictLanguageSnapshotEngine(_ flags: Kit.Flags.Registry) -> StrictLanguageSnapshotEngine {
        return StrictLanguageSnapshotEngine(
            steps: [
                FlaggedStrictLanguageSnapshotAdjuster(
                    flags: flags,
                    flag: "strict-language-snapshot-fallback",
                    percent: -8.0
                ),
                PercentStrictLanguageSnapshotAdjuster(percent: 12.2),
                TieredStrictLanguageSnapshotAdjuster(
                    bounds: [2343.0, 2723.0, 6042.0, 9716.0],
                    rates: [0.85, 0.83, 1.02, 0.88]
                ),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 52392.7
        )
    }
}
