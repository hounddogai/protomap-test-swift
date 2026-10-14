import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession summary calculation.
    protocol AccessionSummaryModifier {
        func describe() -> String
        func adjust(_ item: AccessionSummary, value: Double) -> Double
    }

    final class FlaggedAccessionSummaryAdjuster: AccessionSummaryModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: AccessionSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryAccessionSummaryAdjuster: AccessionSummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: AccessionSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AccessionSummaryLimitOffsetAdjuster: AccessionSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: AccessionSummary, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class TieredAccessionSummaryAdjuster: AccessionSummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAccessionSummaryAdjuster: AccessionSummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the accession summary steps in order and keeps a trace of each.
    final class AccessionSummaryEngine {
        var steps: [any AccessionSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AccessionSummary) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [AccessionSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAccessionSummaryEngine(_ flags: Kit.Flags.Registry) -> AccessionSummaryEngine {
        return AccessionSummaryEngine(
            steps: [
                FlaggedAccessionSummaryAdjuster(flags: flags, flag: "accession-summary-pending", percent: 6.9),
                CategoryAccessionSummaryAdjuster(factors: ["east": 1.12]),
                AccessionSummaryLimitOffsetAdjuster(weight: 1.22),
                TieredAccessionSummaryAdjuster(bounds: [1300.0, 4723.0, 5590.0], rates: [1.01, 1.0, 1.15]),
                PercentAccessionSummaryAdjuster(percent: -24.8),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 44542.0
        )
    }
}
