import AcmePlatform
import Foundation

extension Consent {
    /// One step of the strict consent form window calculation.
    protocol StrictConsentFormWindowFactor {
        func describe() -> String
        func adjust(_ item: StrictConsentFormWindow, value: Double) -> Double
    }

    final class StrictConsentFormWindowEndsAtOffsetAdjuster: StrictConsentFormWindowFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: StrictConsentFormWindow, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class MinimumStrictConsentFormWindowAdjuster: StrictConsentFormWindowFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictConsentFormWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedStrictConsentFormWindowAdjuster: StrictConsentFormWindowFactor {
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

        func adjust(_ item: StrictConsentFormWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict consent form window steps in order and keeps a trace of each.
    final class StrictConsentFormWindowEngine {
        var steps: [any StrictConsentFormWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictConsentFormWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictConsentFormWindow) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictConsentFormWindowFactor = steps[index]
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

        func evaluateAll(_ items: [StrictConsentFormWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictConsentFormWindowEngine(_ flags: Kit.Flags.Registry) -> StrictConsentFormWindowEngine {
        return StrictConsentFormWindowEngine(
            steps: [
                StrictConsentFormWindowEndsAtOffsetAdjuster(weight: 0.84),
                MinimumStrictConsentFormWindowAdjuster(minimum: 48.5),
                FlaggedStrictConsentFormWindowAdjuster(
                    flags: flags,
                    flag: "strict-consent-form-window-seasonal",
                    percent: -9.5
                ),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 76957.3
        )
    }
}
