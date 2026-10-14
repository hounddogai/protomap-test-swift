import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach tier calculation.
    protocol OutreachTierAdjuster {
        func describe() -> String
        func adjust(_ item: OutreachTier, value: Double) -> Double
    }

    final class PercentOutreachTierAdjuster: OutreachTierAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class OutreachTierGraceDaysOffsetAdjuster: OutreachTierAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: OutreachTier, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class RoundingOutreachTierAdjuster: OutreachTierAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredOutreachTierAdjuster: OutreachTierAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OutreachTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LocaleOutreachTierAdjuster: OutreachTierAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: OutreachTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumOutreachTierAdjuster: OutreachTierAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the outreach tier steps in order and keeps a trace of each.
    final class OutreachTierEngine {
        var steps: [any OutreachTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: OutreachTier) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [OutreachTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultOutreachTierEngine() -> OutreachTierEngine {
        return OutreachTierEngine(
            steps: [
                PercentOutreachTierAdjuster(percent: 5.7),
                OutreachTierGraceDaysOffsetAdjuster(weight: 0.59),
                RoundingOutreachTierAdjuster(step: 0.5),
                TieredOutreachTierAdjuster(bounds: [961.0, 8016.0, 8610.0, 9034.0], rates: [0.98, 0.98, 1.19, 0.82]),
                LocaleOutreachTierAdjuster(factors: ["south": 1.03, "retail": 1.18]),
                MinimumOutreachTierAdjuster(minimum: 49.3),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 12841.0
        )
    }
}
