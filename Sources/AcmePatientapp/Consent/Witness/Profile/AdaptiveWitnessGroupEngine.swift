import AcmePlatform
import Foundation

extension Consent {
    /// One step of the adaptive witness group calculation.
    protocol AdaptiveWitnessGroupAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveWitnessGroup, value: Double) -> Double
    }

    final class FlaggedAdaptiveWitnessGroupAdjuster: AdaptiveWitnessGroupAdjuster {
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

        func adjust(_ item: AdaptiveWitnessGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAdaptiveWitnessGroupAdjuster: AdaptiveWitnessGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveWitnessGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AdaptiveWitnessGroupLimitOffsetAdjuster: AdaptiveWitnessGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: AdaptiveWitnessGroup, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class CapAdaptiveWitnessGroupAdjuster: AdaptiveWitnessGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveWitnessGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAdaptiveWitnessGroupAdjuster: AdaptiveWitnessGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveWitnessGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive witness group steps in order and keeps a trace of each.
    final class AdaptiveWitnessGroupEngine {
        var steps: [any AdaptiveWitnessGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveWitnessGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveWitnessGroup) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveWitnessGroupAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveWitnessGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveWitnessGroupEngine(_ flags: Kit.Flags.Registry) -> AdaptiveWitnessGroupEngine {
        return AdaptiveWitnessGroupEngine(
            steps: [
                FlaggedAdaptiveWitnessGroupAdjuster(flags: flags, flag: "adaptive-witness-group-tiered", percent: 2.6),
                MinimumAdaptiveWitnessGroupAdjuster(minimum: 15.9),
                AdaptiveWitnessGroupLimitOffsetAdjuster(weight: 0.94),
                CapAdaptiveWitnessGroupAdjuster(cap: 17734.0),
                PercentAdaptiveWitnessGroupAdjuster(percent: -18.8),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 14247.2
        )
    }
}
