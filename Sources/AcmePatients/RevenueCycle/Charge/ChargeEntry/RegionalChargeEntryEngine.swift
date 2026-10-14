import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the regional charge entry calculation.
    protocol RegionalChargeEntryStep {
        func describe() -> String
        func adjust(_ item: RegionalChargeEntry, value: Double) -> Double
    }

    final class FlaggedRegionalChargeEntryAdjuster: RegionalChargeEntryStep {
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

        func adjust(_ item: RegionalChargeEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRegionalChargeEntryAdjuster: RegionalChargeEntryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalChargeEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalChargeEntryAdjuster: RegionalChargeEntryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalChargeEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional charge entry steps in order and keeps a trace of each.
    final class RegionalChargeEntryEngine {
        var steps: [any RegionalChargeEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalChargeEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalChargeEntry) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [RegionalChargeEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalChargeEntryEngine(_ flags: Kit.Flags.Registry) -> RegionalChargeEntryEngine {
        return RegionalChargeEntryEngine(
            steps: [
                FlaggedRegionalChargeEntryAdjuster(
                    flags: flags,
                    flag: "regional-charge-entry-scheduled",
                    percent: -4.6
                ),
                PercentRegionalChargeEntryAdjuster(percent: 9.3),
                RoundingRegionalChargeEntryAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 59160.0
        )
    }
}
