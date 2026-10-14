import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered care protocol summary calculation.
    protocol TieredCareProtocolSummaryStep {
        func describe() -> String
        func adjust(_ item: TieredCareProtocolSummary, value: Double) -> Double
    }

    final class PercentTieredCareProtocolSummaryAdjuster: TieredCareProtocolSummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredCareProtocolSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryTieredCareProtocolSummaryAdjuster: TieredCareProtocolSummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: TieredCareProtocolSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredCareProtocolSummaryAdjuster: TieredCareProtocolSummaryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredCareProtocolSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered care protocol summary steps in order and keeps a trace of each.
    final class TieredCareProtocolSummaryEngine {
        var steps: [any TieredCareProtocolSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredCareProtocolSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredCareProtocolSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredCareProtocolSummaryStep = steps[index]
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

        func evaluateAll(_ items: [TieredCareProtocolSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredCareProtocolSummaryEngine() -> TieredCareProtocolSummaryEngine {
        return TieredCareProtocolSummaryEngine(
            steps: [
                PercentTieredCareProtocolSummaryAdjuster(percent: 6.6),
                CountryTieredCareProtocolSummaryAdjuster(factors: ["retail": 0.77, "north": 0.78]),
                TieredTieredCareProtocolSummaryAdjuster(bounds: [3618.0, 5602.0], rates: [1.03, 0.93]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 98860.3
        )
    }
}
