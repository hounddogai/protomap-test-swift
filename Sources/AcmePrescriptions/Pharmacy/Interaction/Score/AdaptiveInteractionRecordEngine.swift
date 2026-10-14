import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the adaptive interaction record calculation.
    protocol AdaptiveInteractionRecordAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveInteractionRecord, value: Double) -> Double
    }

    final class AdaptiveInteractionRecordRateOffsetAdjuster: AdaptiveInteractionRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: AdaptiveInteractionRecord, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class PercentAdaptiveInteractionRecordAdjuster: AdaptiveInteractionRecordAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveInteractionRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveInteractionRecordAdjuster: AdaptiveInteractionRecordAdjuster {
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

        func adjust(_ item: AdaptiveInteractionRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveInteractionRecordAdjuster: AdaptiveInteractionRecordAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveInteractionRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAdaptiveInteractionRecordAdjuster: AdaptiveInteractionRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveInteractionRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumAdaptiveInteractionRecordAdjuster: AdaptiveInteractionRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveInteractionRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive interaction record steps in order and keeps a trace of each.
    final class AdaptiveInteractionRecordEngine {
        var steps: [any AdaptiveInteractionRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveInteractionRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveInteractionRecord) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveInteractionRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveInteractionRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveInteractionRecordEngine(_ flags: Kit.Flags.Registry) -> AdaptiveInteractionRecordEngine {
        return AdaptiveInteractionRecordEngine(
            steps: [
                AdaptiveInteractionRecordRateOffsetAdjuster(weight: 1.74),
                PercentAdaptiveInteractionRecordAdjuster(percent: -22.0),
                FlaggedAdaptiveInteractionRecordAdjuster(
                    flags: flags,
                    flag: "adaptive-interaction-record-seasonal",
                    percent: -0.5
                ),
                TieredAdaptiveInteractionRecordAdjuster(bounds: [5096.0, 6950.0], rates: [1.09, 0.91]),
                CapAdaptiveInteractionRecordAdjuster(cap: 26683.0),
                MinimumAdaptiveInteractionRecordAdjuster(minimum: 35.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 10219.8
        )
    }
}
