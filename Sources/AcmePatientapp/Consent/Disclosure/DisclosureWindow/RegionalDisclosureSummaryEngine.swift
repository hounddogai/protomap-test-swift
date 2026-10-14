import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional disclosure summary calculation.
    protocol RegionalDisclosureSummaryModifier {
        func describe() -> String
        func adjust(_ item: RegionalDisclosureSummary, value: Double) -> Double
    }

    final class RegionalDisclosureSummaryMinimumOffsetAdjuster: RegionalDisclosureSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: RegionalDisclosureSummary, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class CountryRegionalDisclosureSummaryAdjuster: RegionalDisclosureSummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RegionalDisclosureSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRegionalDisclosureSummaryAdjuster: RegionalDisclosureSummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalDisclosureSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRegionalDisclosureSummaryAdjuster: RegionalDisclosureSummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalDisclosureSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalDisclosureSummaryAdjuster: RegionalDisclosureSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalDisclosureSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional disclosure summary steps in order and keeps a trace of each.
    final class RegionalDisclosureSummaryEngine {
        var steps: [any RegionalDisclosureSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalDisclosureSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalDisclosureSummary) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalDisclosureSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalDisclosureSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalDisclosureSummaryEngine() -> RegionalDisclosureSummaryEngine {
        return RegionalDisclosureSummaryEngine(
            steps: [
                RegionalDisclosureSummaryMinimumOffsetAdjuster(weight: 1.61),
                CountryRegionalDisclosureSummaryAdjuster(factors: ["west": 1.37]),
                CapRegionalDisclosureSummaryAdjuster(cap: 23801.0),
                PercentRegionalDisclosureSummaryAdjuster(percent: -19.0),
                MinimumRegionalDisclosureSummaryAdjuster(minimum: 26.5),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 59359.1
        )
    }
}
