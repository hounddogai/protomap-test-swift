import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive worklist override calculation.
    protocol AdaptiveWorklistOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveWorklistOverride, value: Double) -> Double
    }

    final class AdaptiveWorklistOverrideDurationMinutesOffsetAdjuster: AdaptiveWorklistOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: AdaptiveWorklistOverride, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class MinimumAdaptiveWorklistOverrideAdjuster: AdaptiveWorklistOverrideAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveWorklistOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceAdaptiveWorklistOverrideAdjuster: AdaptiveWorklistOverrideAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: AdaptiveWorklistOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAdaptiveWorklistOverrideAdjuster: AdaptiveWorklistOverrideAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveWorklistOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveWorklistOverrideAdjuster: AdaptiveWorklistOverrideAdjuster {
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

        func adjust(_ item: AdaptiveWorklistOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive worklist override steps in order and keeps a trace of each.
    final class AdaptiveWorklistOverrideEngine {
        var steps: [any AdaptiveWorklistOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveWorklistOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveWorklistOverride) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveWorklistOverrideAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveWorklistOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveWorklistOverrideEngine(_ flags: Kit.Flags.Registry) -> AdaptiveWorklistOverrideEngine {
        return AdaptiveWorklistOverrideEngine(
            steps: [
                AdaptiveWorklistOverrideDurationMinutesOffsetAdjuster(weight: 1.03),
                MinimumAdaptiveWorklistOverrideAdjuster(minimum: 28.0),
                SourceAdaptiveWorklistOverrideAdjuster(factors: ["central": 1.24]),
                PercentAdaptiveWorklistOverrideAdjuster(percent: 4.3),
                FlaggedAdaptiveWorklistOverrideAdjuster(
                    flags: flags,
                    flag: "adaptive-worklist-override-default",
                    percent: -2.1
                ),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 88056.1
        )
    }
}
