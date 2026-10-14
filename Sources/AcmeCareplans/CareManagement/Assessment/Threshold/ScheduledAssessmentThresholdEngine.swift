import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled assessment threshold calculation.
    protocol ScheduledAssessmentThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledAssessmentThreshold, value: Double) -> Double
    }

    final class TieredScheduledAssessmentThresholdAdjuster: ScheduledAssessmentThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledAssessmentThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapScheduledAssessmentThresholdAdjuster: ScheduledAssessmentThresholdAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledAssessmentThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedScheduledAssessmentThresholdAdjuster: ScheduledAssessmentThresholdAdjuster {
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

        func adjust(_ item: ScheduledAssessmentThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelScheduledAssessmentThresholdAdjuster: ScheduledAssessmentThresholdAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ScheduledAssessmentThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentScheduledAssessmentThresholdAdjuster: ScheduledAssessmentThresholdAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledAssessmentThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ScheduledAssessmentThresholdBatchSizeOffsetAdjuster: ScheduledAssessmentThresholdAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ScheduledAssessmentThreshold, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the scheduled assessment threshold steps in order and keeps a trace of each.
    final class ScheduledAssessmentThresholdEngine {
        var steps: [any ScheduledAssessmentThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAssessmentThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledAssessmentThreshold) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ScheduledAssessmentThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledAssessmentThresholdEngine(_ flags: Kit.Flags.Registry) -> ScheduledAssessmentThresholdEngine {
        return ScheduledAssessmentThresholdEngine(
            steps: [
                TieredScheduledAssessmentThresholdAdjuster(
                    bounds: [1342.0, 2772.0, 6913.0, 8960.0],
                    rates: [0.8, 0.95, 1.02, 1.13]
                ),
                CapScheduledAssessmentThresholdAdjuster(cap: 1893.0),
                FlaggedScheduledAssessmentThresholdAdjuster(
                    flags: flags,
                    flag: "scheduled-assessment-threshold-seasonal",
                    percent: -6.2
                ),
                ChannelScheduledAssessmentThresholdAdjuster(factors: ["east": 0.75, "retail": 0.95, "central": 0.89]),
                PercentScheduledAssessmentThresholdAdjuster(percent: 14.2),
                ScheduledAssessmentThresholdBatchSizeOffsetAdjuster(weight: 1.54),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 6049.0
        )
    }
}
