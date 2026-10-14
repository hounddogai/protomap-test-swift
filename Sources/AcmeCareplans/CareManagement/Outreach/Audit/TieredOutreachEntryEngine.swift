import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered outreach entry calculation.
    protocol TieredOutreachEntryModifier {
        func describe() -> String
        func adjust(_ item: TieredOutreachEntry, value: Double) -> Double
    }

    final class TieredTieredOutreachEntryAdjuster: TieredOutreachEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredOutreachEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ChannelTieredOutreachEntryAdjuster: TieredOutreachEntryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: TieredOutreachEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTieredOutreachEntryAdjuster: TieredOutreachEntryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredOutreachEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTieredOutreachEntryAdjuster: TieredOutreachEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredOutreachEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered outreach entry steps in order and keeps a trace of each.
    final class TieredOutreachEntryEngine {
        var steps: [any TieredOutreachEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredOutreachEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredOutreachEntry) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredOutreachEntryModifier = steps[index]
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

        func evaluateAll(_ items: [TieredOutreachEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredOutreachEntryEngine() -> TieredOutreachEntryEngine {
        return TieredOutreachEntryEngine(
            steps: [
                TieredTieredOutreachEntryAdjuster(bounds: [6976.0, 8929.0, 9112.0], rates: [1.18, 0.91, 0.81]),
                ChannelTieredOutreachEntryAdjuster(factors: ["west": 0.89, "east": 1.34, "retail": 1.28]),
                MinimumTieredOutreachEntryAdjuster(minimum: 48.6),
                PercentTieredOutreachEntryAdjuster(percent: -0.1),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 40612.4
        )
    }
}
