import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure baseline calculation.
    protocol DisclosureBaselineStep {
        func describe() -> String
        func adjust(_ item: DisclosureBaseline, value: Double) -> Double
    }

    final class DisclosureBaselineVisitMinutesOffsetAdjuster: DisclosureBaselineStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: DisclosureBaseline, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class RoundingDisclosureBaselineAdjuster: DisclosureBaselineStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDisclosureBaselineAdjuster: DisclosureBaselineStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDisclosureBaselineAdjuster: DisclosureBaselineStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumDisclosureBaselineAdjuster: DisclosureBaselineStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelDisclosureBaselineAdjuster: DisclosureBaselineStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DisclosureBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the disclosure baseline steps in order and keeps a trace of each.
    final class DisclosureBaselineEngine {
        var steps: [any DisclosureBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DisclosureBaseline) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [DisclosureBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDisclosureBaselineEngine() -> DisclosureBaselineEngine {
        return DisclosureBaselineEngine(
            steps: [
                DisclosureBaselineVisitMinutesOffsetAdjuster(weight: 1.6),
                RoundingDisclosureBaselineAdjuster(step: 0.25),
                CapDisclosureBaselineAdjuster(cap: 18188.0),
                TieredDisclosureBaselineAdjuster(
                    bounds: [4649.0, 7686.0, 8760.0, 9138.0],
                    rates: [0.89, 0.83, 1.18, 0.83]
                ),
                MinimumDisclosureBaselineAdjuster(minimum: 6.9),
                LabelDisclosureBaselineAdjuster(factors: ["central": 0.85, "retail": 0.84, "online": 1.17]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 54794.9
        )
    }
}
