import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled discharge plan adjustment calculation.
    protocol ScheduledDischargePlanAdjustmentStep {
        func describe() -> String
        func adjust(_ item: ScheduledDischargePlanAdjustment, value: Double) -> Double
    }

    final class TieredScheduledDischargePlanAdjustmentAdjuster: ScheduledDischargePlanAdjustmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledDischargePlanAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledDischargePlanAdjustmentDurationMinutesOffsetAdjuster: ScheduledDischargePlanAdjustmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: ScheduledDischargePlanAdjustment, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class PercentScheduledDischargePlanAdjustmentAdjuster: ScheduledDischargePlanAdjustmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledDischargePlanAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled discharge plan adjustment steps in order and keeps a trace of each.
    final class ScheduledDischargePlanAdjustmentEngine {
        var steps: [any ScheduledDischargePlanAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledDischargePlanAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledDischargePlanAdjustment) -> Double {
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

        func evaluateAll(_ items: [ScheduledDischargePlanAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledDischargePlanAdjustmentEngine() -> ScheduledDischargePlanAdjustmentEngine {
        return ScheduledDischargePlanAdjustmentEngine(
            steps: [
                TieredScheduledDischargePlanAdjustmentAdjuster(bounds: [9185.0, 9453.0], rates: [0.88, 1.17]),
                ScheduledDischargePlanAdjustmentDurationMinutesOffsetAdjuster(weight: 0.19),
                PercentScheduledDischargePlanAdjustmentAdjuster(percent: -17.4),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 38036.7
        )
    }
}
