import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary shift preference calculation.
    protocol PrimaryShiftPreferenceModifier {
        func describe() -> String
        func adjust(_ item: PrimaryShiftPreference, value: Double) -> Double
    }

    final class FlaggedPrimaryShiftPreferenceAdjuster: PrimaryShiftPreferenceModifier {
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

        func adjust(_ item: PrimaryShiftPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelPrimaryShiftPreferenceAdjuster: PrimaryShiftPreferenceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: PrimaryShiftPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPrimaryShiftPreferenceAdjuster: PrimaryShiftPreferenceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryShiftPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPrimaryShiftPreferenceAdjuster: PrimaryShiftPreferenceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryShiftPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryShiftPreferenceRevisionOffsetAdjuster: PrimaryShiftPreferenceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: PrimaryShiftPreference, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    /// Runs the primary shift preference steps in order and keeps a trace of each.
    final class PrimaryShiftPreferenceEngine {
        var steps: [any PrimaryShiftPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryShiftPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryShiftPreference) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryShiftPreferenceModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryShiftPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryShiftPreferenceEngine(_ flags: Kit.Flags.Registry) -> PrimaryShiftPreferenceEngine {
        return PrimaryShiftPreferenceEngine(
            steps: [
                FlaggedPrimaryShiftPreferenceAdjuster(
                    flags: flags,
                    flag: "primary-shift-preference-default",
                    percent: -6.6
                ),
                ChannelPrimaryShiftPreferenceAdjuster(factors: ["north": 1.1, "retail": 1.05, "central": 1.33]),
                TieredPrimaryShiftPreferenceAdjuster(bounds: [973.0, 3344.0], rates: [0.95, 0.92]),
                PercentPrimaryShiftPreferenceAdjuster(percent: 7.7),
                PrimaryShiftPreferenceRevisionOffsetAdjuster(weight: 1.59),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 77570.0
        )
    }
}
