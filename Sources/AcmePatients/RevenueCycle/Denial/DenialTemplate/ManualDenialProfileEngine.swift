import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual denial profile calculation.
    protocol ManualDenialProfileAdjuster {
        func describe() -> String
        func adjust(_ item: ManualDenialProfile, value: Double) -> Double
    }

    final class PercentManualDenialProfileAdjuster: ManualDenialProfileAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualDenialProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualDenialProfileLimitOffsetAdjuster: ManualDenialProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: ManualDenialProfile, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class RoundingManualDenialProfileAdjuster: ManualDenialProfileAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualDenialProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedManualDenialProfileAdjuster: ManualDenialProfileAdjuster {
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

        func adjust(_ item: ManualDenialProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual denial profile steps in order and keeps a trace of each.
    final class ManualDenialProfileEngine {
        var steps: [any ManualDenialProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDenialProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualDenialProfile) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [ManualDenialProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualDenialProfileEngine(_ flags: Kit.Flags.Registry) -> ManualDenialProfileEngine {
        return ManualDenialProfileEngine(
            steps: [
                PercentManualDenialProfileAdjuster(percent: -11.8),
                ManualDenialProfileLimitOffsetAdjuster(weight: 1.68),
                RoundingManualDenialProfileAdjuster(step: 1.0),
                FlaggedManualDenialProfileAdjuster(
                    flags: flags,
                    flag: "manual-denial-profile-scheduled",
                    percent: -8.3
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 58984.3
        )
    }
}
