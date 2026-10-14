import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the scheduled care protocol summary calculation.
    protocol ScheduledCareProtocolSummaryModifier {
        func describe() -> String
        func adjust(_ item: ScheduledCareProtocolSummary, value: Double) -> Double
    }

    final class MinimumScheduledCareProtocolSummaryAdjuster: ScheduledCareProtocolSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledCareProtocolSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledCareProtocolSummaryAdjuster: ScheduledCareProtocolSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledCareProtocolSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FacilityScheduledCareProtocolSummaryAdjuster: ScheduledCareProtocolSummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ScheduledCareProtocolSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentScheduledCareProtocolSummaryAdjuster: ScheduledCareProtocolSummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledCareProtocolSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled care protocol summary steps in order and keeps a trace of each.
    final class ScheduledCareProtocolSummaryEngine {
        var steps: [any ScheduledCareProtocolSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCareProtocolSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledCareProtocolSummary) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ScheduledCareProtocolSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledCareProtocolSummaryEngine() -> ScheduledCareProtocolSummaryEngine {
        return ScheduledCareProtocolSummaryEngine(
            steps: [
                MinimumScheduledCareProtocolSummaryAdjuster(minimum: 32.7),
                RoundingScheduledCareProtocolSummaryAdjuster(step: 1.0),
                FacilityScheduledCareProtocolSummaryAdjuster(factors: ["north": 1.02]),
                PercentScheduledCareProtocolSummaryAdjuster(percent: -18.4),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 66585.8
        )
    }
}
