import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim preference calculation.
    protocol ClaimPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: ClaimPreference, value: Double) -> Double
    }

    final class ClaimPreferenceRatioOffsetAdjuster: ClaimPreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ClaimPreference, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class CapClaimPreferenceAdjuster: ClaimPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumClaimPreferenceAdjuster: ClaimPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedClaimPreferenceAdjuster: ClaimPreferenceAdjuster {
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

        func adjust(_ item: ClaimPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelClaimPreferenceAdjuster: ClaimPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ClaimPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the claim preference steps in order and keeps a trace of each.
    final class ClaimPreferenceEngine {
        var steps: [any ClaimPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ClaimPreference) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimPreferenceAdjuster = steps[index]
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

        func evaluateAll(_ items: [ClaimPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultClaimPreferenceEngine(_ flags: Kit.Flags.Registry) -> ClaimPreferenceEngine {
        return ClaimPreferenceEngine(
            steps: [
                ClaimPreferenceRatioOffsetAdjuster(weight: 0.83),
                CapClaimPreferenceAdjuster(cap: 5955.0),
                MinimumClaimPreferenceAdjuster(minimum: 30.1),
                FlaggedClaimPreferenceAdjuster(flags: flags, flag: "claim-preference-seasonal", percent: -7.5),
                LabelClaimPreferenceAdjuster(factors: ["online": 1.01, "north": 1.19, "west": 1.21]),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 57484.3
        )
    }
}
