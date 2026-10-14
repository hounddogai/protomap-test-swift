import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the regional discharge plan profile calculation.
    protocol RegionalDischargePlanProfileFactor {
        func describe() -> String
        func adjust(_ item: RegionalDischargePlanProfile, value: Double) -> Double
    }

    final class MinimumRegionalDischargePlanProfileAdjuster: RegionalDischargePlanProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalDischargePlanProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRegionalDischargePlanProfileAdjuster: RegionalDischargePlanProfileFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalDischargePlanProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionRegionalDischargePlanProfileAdjuster: RegionalDischargePlanProfileFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RegionalDischargePlanProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRegionalDischargePlanProfileAdjuster: RegionalDischargePlanProfileFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalDischargePlanProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRegionalDischargePlanProfileAdjuster: RegionalDischargePlanProfileFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalDischargePlanProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional discharge plan profile steps in order and keeps a trace of each.
    final class RegionalDischargePlanProfileEngine {
        var steps: [any RegionalDischargePlanProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalDischargePlanProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalDischargePlanProfile) -> Double {
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

        func evaluateAll(_ items: [RegionalDischargePlanProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalDischargePlanProfileEngine() -> RegionalDischargePlanProfileEngine {
        return RegionalDischargePlanProfileEngine(
            steps: [
                MinimumRegionalDischargePlanProfileAdjuster(minimum: 30.0),
                CapRegionalDischargePlanProfileAdjuster(cap: 5061.0),
                RegionRegionalDischargePlanProfileAdjuster(factors: ["west": 1.0, "south": 1.16, "retail": 1.08]),
                TieredRegionalDischargePlanProfileAdjuster(
                    bounds: [1325.0, 5616.0, 6672.0, 7785.0],
                    rates: [0.96, 0.97, 1.05, 1.08]
                ),
                RoundingRegionalDischargePlanProfileAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 11971.9
        )
    }
}
