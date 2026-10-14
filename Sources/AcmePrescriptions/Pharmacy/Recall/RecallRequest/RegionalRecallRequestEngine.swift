import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the regional recall request calculation.
    protocol RegionalRecallRequestModifier {
        func describe() -> String
        func adjust(_ item: RegionalRecallRequest, value: Double) -> Double
    }

    final class RoundingRegionalRecallRequestAdjuster: RegionalRecallRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalRecallRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardRegionalRecallRequestAdjuster: RegionalRecallRequestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: RegionalRecallRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RegionalRecallRequestVisitMinutesOffsetAdjuster: RegionalRecallRequestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: RegionalRecallRequest, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class MinimumRegionalRecallRequestAdjuster: RegionalRecallRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalRecallRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRegionalRecallRequestAdjuster: RegionalRecallRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalRecallRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional recall request steps in order and keeps a trace of each.
    final class RegionalRecallRequestEngine {
        var steps: [any RegionalRecallRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalRecallRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalRecallRequest) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [RegionalRecallRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalRecallRequestEngine() -> RegionalRecallRequestEngine {
        return RegionalRecallRequestEngine(
            steps: [
                RoundingRegionalRecallRequestAdjuster(step: 5.0),
                WardRegionalRecallRequestAdjuster(factors: ["west": 1.23, "east": 0.8]),
                RegionalRecallRequestVisitMinutesOffsetAdjuster(weight: 1.03),
                MinimumRegionalRecallRequestAdjuster(minimum: 18.4),
                PercentRegionalRecallRequestAdjuster(percent: -5.3),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 16568.3
        )
    }
}
