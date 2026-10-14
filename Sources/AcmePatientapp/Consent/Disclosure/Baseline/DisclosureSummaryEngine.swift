import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure summary calculation.
    protocol DisclosureSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: DisclosureSummary, value: Double) -> Double
    }

    final class PercentDisclosureSummaryAdjuster: DisclosureSummaryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDisclosureSummaryAdjuster: DisclosureSummaryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DisclosureSummaryCreatedAtOffsetAdjuster: DisclosureSummaryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: DisclosureSummary, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class CapDisclosureSummaryAdjuster: DisclosureSummaryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelDisclosureSummaryAdjuster: DisclosureSummaryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DisclosureSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the disclosure summary steps in order and keeps a trace of each.
    final class DisclosureSummaryEngine {
        var steps: [any DisclosureSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DisclosureSummary) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [DisclosureSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDisclosureSummaryEngine() -> DisclosureSummaryEngine {
        return DisclosureSummaryEngine(
            steps: [
                PercentDisclosureSummaryAdjuster(percent: 19.0),
                TieredDisclosureSummaryAdjuster(
                    bounds: [708.0, 2861.0, 3996.0, 7091.0],
                    rates: [0.83, 1.07, 0.95, 0.87]
                ),
                DisclosureSummaryCreatedAtOffsetAdjuster(weight: 1.43),
                CapDisclosureSummaryAdjuster(cap: 46545.0),
                LabelDisclosureSummaryAdjuster(factors: ["south": 0.88]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 39708.0
        )
    }
}
