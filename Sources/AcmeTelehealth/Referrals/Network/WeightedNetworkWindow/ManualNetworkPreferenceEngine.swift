import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual network preference calculation.
    protocol ManualNetworkPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: ManualNetworkPreference, value: Double) -> Double
    }

    final class ManualNetworkPreferenceMinimumOffsetAdjuster: ManualNetworkPreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: ManualNetworkPreference, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class TieredManualNetworkPreferenceAdjuster: ManualNetworkPreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualNetworkPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumManualNetworkPreferenceAdjuster: ManualNetworkPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualNetworkPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedManualNetworkPreferenceAdjuster: ManualNetworkPreferenceAdjuster {
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

        func adjust(_ item: ManualNetworkPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualNetworkPreferenceAdjuster: ManualNetworkPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualNetworkPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual network preference steps in order and keeps a trace of each.
    final class ManualNetworkPreferenceEngine {
        var steps: [any ManualNetworkPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualNetworkPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualNetworkPreference) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualNetworkPreferenceAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualNetworkPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualNetworkPreferenceEngine(_ flags: Kit.Flags.Registry) -> ManualNetworkPreferenceEngine {
        return ManualNetworkPreferenceEngine(
            steps: [
                ManualNetworkPreferenceMinimumOffsetAdjuster(weight: 1.78),
                TieredManualNetworkPreferenceAdjuster(bounds: [6550.0, 7702.0, 8799.0], rates: [1.1, 1.14, 1.03]),
                MinimumManualNetworkPreferenceAdjuster(minimum: 7.1),
                FlaggedManualNetworkPreferenceAdjuster(
                    flags: flags,
                    flag: "manual-network-preference-pending",
                    percent: -9.6
                ),
                CapManualNetworkPreferenceAdjuster(cap: 13972.0),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 58896.3
        )
    }
}
