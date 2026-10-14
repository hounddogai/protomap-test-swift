import AcmePlatform
import Foundation

extension Consent {
    /// One step of the primary disclosure summary calculation.
    protocol PrimaryDisclosureSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryDisclosureSummary, value: Double) -> Double
    }

    final class MinimumPrimaryDisclosureSummaryAdjuster: PrimaryDisclosureSummaryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryDisclosureSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPrimaryDisclosureSummaryAdjuster: PrimaryDisclosureSummaryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryDisclosureSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PrimaryDisclosureSummaryWeightOffsetAdjuster: PrimaryDisclosureSummaryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: PrimaryDisclosureSummary, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class PercentPrimaryDisclosureSummaryAdjuster: PrimaryDisclosureSummaryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryDisclosureSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionPrimaryDisclosureSummaryAdjuster: PrimaryDisclosureSummaryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: PrimaryDisclosureSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary disclosure summary steps in order and keeps a trace of each.
    final class PrimaryDisclosureSummaryEngine {
        var steps: [any PrimaryDisclosureSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryDisclosureSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryDisclosureSummary) -> Double {
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

        func evaluateAll(_ items: [PrimaryDisclosureSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryDisclosureSummaryEngine() -> PrimaryDisclosureSummaryEngine {
        return PrimaryDisclosureSummaryEngine(
            steps: [
                MinimumPrimaryDisclosureSummaryAdjuster(minimum: 2.3),
                TieredPrimaryDisclosureSummaryAdjuster(
                    bounds: [1920.0, 5559.0, 5883.0, 9202.0],
                    rates: [0.91, 0.87, 0.85, 0.99]
                ),
                PrimaryDisclosureSummaryWeightOffsetAdjuster(weight: 1.12),
                PercentPrimaryDisclosureSummaryAdjuster(percent: 18.3),
                RegionPrimaryDisclosureSummaryAdjuster(factors: ["east": 0.79, "north": 1.33, "central": 0.73]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 15725.2
        )
    }
}
