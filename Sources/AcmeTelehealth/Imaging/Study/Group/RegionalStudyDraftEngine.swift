import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the regional study draft calculation.
    protocol RegionalStudyDraftModifier {
        func describe() -> String
        func adjust(_ item: RegionalStudyDraft, value: Double) -> Double
    }

    final class TieredRegionalStudyDraftAdjuster: RegionalStudyDraftModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalStudyDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRegionalStudyDraftAdjuster: RegionalStudyDraftModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalStudyDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardRegionalStudyDraftAdjuster: RegionalStudyDraftModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: RegionalStudyDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional study draft steps in order and keeps a trace of each.
    final class RegionalStudyDraftEngine {
        var steps: [any RegionalStudyDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalStudyDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalStudyDraft) -> Double {
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

        func evaluateAll(_ items: [RegionalStudyDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalStudyDraftEngine() -> RegionalStudyDraftEngine {
        return RegionalStudyDraftEngine(
            steps: [
                TieredRegionalStudyDraftAdjuster(
                    bounds: [2165.0, 3395.0, 3728.0, 4027.0],
                    rates: [1.01, 1.07, 0.95, 0.95]
                ),
                RoundingRegionalStudyDraftAdjuster(step: 5.0),
                WardRegionalStudyDraftAdjuster(factors: ["online": 0.96, "west": 1.31, "south": 1.24]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 61650.4
        )
    }
}
