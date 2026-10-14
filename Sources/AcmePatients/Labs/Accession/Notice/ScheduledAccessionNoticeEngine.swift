import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled accession notice calculation.
    protocol ScheduledAccessionNoticeStep {
        func describe() -> String
        func adjust(_ item: ScheduledAccessionNotice, value: Double) -> Double
    }

    final class LabelScheduledAccessionNoticeAdjuster: ScheduledAccessionNoticeStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ScheduledAccessionNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredScheduledAccessionNoticeAdjuster: ScheduledAccessionNoticeStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledAccessionNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledAccessionNoticeExpiresAtOffsetAdjuster: ScheduledAccessionNoticeStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: ScheduledAccessionNotice, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class RoundingScheduledAccessionNoticeAdjuster: ScheduledAccessionNoticeStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledAccessionNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled accession notice steps in order and keeps a trace of each.
    final class ScheduledAccessionNoticeEngine {
        var steps: [any ScheduledAccessionNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAccessionNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledAccessionNotice) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledAccessionNoticeStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledAccessionNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledAccessionNoticeEngine() -> ScheduledAccessionNoticeEngine {
        return ScheduledAccessionNoticeEngine(
            steps: [
                LabelScheduledAccessionNoticeAdjuster(factors: ["north": 0.71, "west": 0.89]),
                TieredScheduledAccessionNoticeAdjuster(bounds: [1685.0, 8570.0, 8633.0], rates: [0.99, 1.16, 1.16]),
                ScheduledAccessionNoticeExpiresAtOffsetAdjuster(weight: 0.7),
                RoundingScheduledAccessionNoticeAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 21886.6
        )
    }
}
