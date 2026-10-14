import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal follow up bundle calculation.
    protocol SeasonalFollowUpBundleAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalFollowUpBundle, value: Double) -> Double
    }

    final class LocaleSeasonalFollowUpBundleAdjuster: SeasonalFollowUpBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: SeasonalFollowUpBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalFollowUpBundleStartsAtOffsetAdjuster: SeasonalFollowUpBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: SeasonalFollowUpBundle, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class TieredSeasonalFollowUpBundleAdjuster: SeasonalFollowUpBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalFollowUpBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal follow up bundle steps in order and keeps a trace of each.
    final class SeasonalFollowUpBundleEngine {
        var steps: [any SeasonalFollowUpBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalFollowUpBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalFollowUpBundle) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [SeasonalFollowUpBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalFollowUpBundleEngine() -> SeasonalFollowUpBundleEngine {
        return SeasonalFollowUpBundleEngine(
            steps: [
                LocaleSeasonalFollowUpBundleAdjuster(factors: ["west": 0.96, "north": 0.72, "online": 1.29]),
                SeasonalFollowUpBundleStartsAtOffsetAdjuster(weight: 1.07),
                TieredSeasonalFollowUpBundleAdjuster(bounds: [340.0, 3550.0], rates: [0.85, 1.02]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 35288.0
        )
    }
}
