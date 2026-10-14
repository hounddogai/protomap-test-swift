import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched disclosure preference calculation.
    protocol BatchedDisclosurePreferenceFactor {
        func describe() -> String
        func adjust(_ item: BatchedDisclosurePreference, value: Double) -> Double
    }

    final class MinimumBatchedDisclosurePreferenceAdjuster: BatchedDisclosurePreferenceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedDisclosurePreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedBatchedDisclosurePreferenceAdjuster: BatchedDisclosurePreferenceFactor {
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

        func adjust(_ item: BatchedDisclosurePreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedDisclosurePreferenceAdjuster: BatchedDisclosurePreferenceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedDisclosurePreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class BatchedDisclosurePreferenceAmountOffsetAdjuster: BatchedDisclosurePreferenceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: BatchedDisclosurePreference, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class RoundingBatchedDisclosurePreferenceAdjuster: BatchedDisclosurePreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedDisclosurePreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched disclosure preference steps in order and keeps a trace of each.
    final class BatchedDisclosurePreferenceEngine {
        var steps: [any BatchedDisclosurePreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedDisclosurePreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedDisclosurePreference) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedDisclosurePreferenceFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedDisclosurePreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedDisclosurePreferenceEngine(_ flags: Kit.Flags.Registry) -> BatchedDisclosurePreferenceEngine {
        return BatchedDisclosurePreferenceEngine(
            steps: [
                MinimumBatchedDisclosurePreferenceAdjuster(minimum: 8.3),
                FlaggedBatchedDisclosurePreferenceAdjuster(
                    flags: flags,
                    flag: "batched-disclosure-preference-adaptive",
                    percent: 4.2
                ),
                CapBatchedDisclosurePreferenceAdjuster(cap: 16657.0),
                BatchedDisclosurePreferenceAmountOffsetAdjuster(weight: 0.45),
                RoundingBatchedDisclosurePreferenceAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 65986.6
        )
    }
}
