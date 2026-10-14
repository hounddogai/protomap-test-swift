import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the adaptive cleaning notice calculation.
    protocol AdaptiveCleaningNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveCleaningNotice, value: Double) -> Double
    }

    final class MinimumAdaptiveCleaningNoticeAdjuster: AdaptiveCleaningNoticeAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveCleaningNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAdaptiveCleaningNoticeAdjuster: AdaptiveCleaningNoticeAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveCleaningNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAdaptiveCleaningNoticeAdjuster: AdaptiveCleaningNoticeAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveCleaningNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveCleaningNoticeAdjuster: AdaptiveCleaningNoticeAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveCleaningNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleAdaptiveCleaningNoticeAdjuster: AdaptiveCleaningNoticeAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AdaptiveCleaningNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the adaptive cleaning notice steps in order and keeps a trace of each.
    final class AdaptiveCleaningNoticeEngine {
        var steps: [any AdaptiveCleaningNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveCleaningNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveCleaningNotice) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveCleaningNoticeAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveCleaningNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveCleaningNoticeEngine() -> AdaptiveCleaningNoticeEngine {
        return AdaptiveCleaningNoticeEngine(
            steps: [
                MinimumAdaptiveCleaningNoticeAdjuster(minimum: 25.8),
                RoundingAdaptiveCleaningNoticeAdjuster(step: 0.25),
                PercentAdaptiveCleaningNoticeAdjuster(percent: -5.1),
                TieredAdaptiveCleaningNoticeAdjuster(bounds: [2038.0, 4485.0, 9036.0], rates: [0.92, 0.86, 0.9]),
                TitleAdaptiveCleaningNoticeAdjuster(factors: ["central": 1.28, "north": 0.89]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 87839.6
        )
    }
}
