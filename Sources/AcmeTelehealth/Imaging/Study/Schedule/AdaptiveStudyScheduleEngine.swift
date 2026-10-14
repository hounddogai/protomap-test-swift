import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive study schedule calculation.
    protocol AdaptiveStudyScheduleFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveStudySchedule, value: Double) -> Double
    }

    final class NameAdaptiveStudyScheduleAdjuster: AdaptiveStudyScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AdaptiveStudySchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAdaptiveStudyScheduleAdjuster: AdaptiveStudyScheduleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveStudySchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAdaptiveStudyScheduleAdjuster: AdaptiveStudyScheduleFactor {
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

        func adjust(_ item: AdaptiveStudySchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AdaptiveStudyScheduleBatchSizeOffsetAdjuster: AdaptiveStudyScheduleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: AdaptiveStudySchedule, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class PercentAdaptiveStudyScheduleAdjuster: AdaptiveStudyScheduleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveStudySchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveStudyScheduleAdjuster: AdaptiveStudyScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveStudySchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive study schedule steps in order and keeps a trace of each.
    final class AdaptiveStudyScheduleEngine {
        var steps: [any AdaptiveStudyScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveStudyScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveStudySchedule) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [AdaptiveStudySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveStudyScheduleEngine(_ flags: Kit.Flags.Registry) -> AdaptiveStudyScheduleEngine {
        return AdaptiveStudyScheduleEngine(
            steps: [
                NameAdaptiveStudyScheduleAdjuster(factors: ["south": 1.35]),
                TieredAdaptiveStudyScheduleAdjuster(bounds: [2718.0, 2946.0, 9533.0], rates: [0.99, 1.04, 1.15]),
                FlaggedAdaptiveStudyScheduleAdjuster(
                    flags: flags,
                    flag: "adaptive-study-schedule-scheduled",
                    percent: 9.9
                ),
                AdaptiveStudyScheduleBatchSizeOffsetAdjuster(weight: 0.56),
                PercentAdaptiveStudyScheduleAdjuster(percent: -12.0),
                CapAdaptiveStudyScheduleAdjuster(cap: 8140.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 65471.0
        )
    }
}
