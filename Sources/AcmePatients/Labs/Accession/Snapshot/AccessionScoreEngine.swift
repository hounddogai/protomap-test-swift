import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession score calculation.
    protocol AccessionScoreFactor {
        func describe() -> String
        func adjust(_ item: AccessionScore, value: Double) -> Double
    }

    final class MinimumAccessionScoreAdjuster: AccessionScoreFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAccessionScoreAdjuster: AccessionScoreFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAccessionScoreAdjuster: AccessionScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AccessionScoreRefillsOffsetAdjuster: AccessionScoreFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: AccessionScore, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class RegionAccessionScoreAdjuster: AccessionScoreFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: AccessionScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the accession score steps in order and keeps a trace of each.
    final class AccessionScoreEngine {
        var steps: [any AccessionScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AccessionScore) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [AccessionScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAccessionScoreEngine() -> AccessionScoreEngine {
        return AccessionScoreEngine(
            steps: [
                MinimumAccessionScoreAdjuster(minimum: 47.5),
                CapAccessionScoreAdjuster(cap: 21165.0),
                RoundingAccessionScoreAdjuster(step: 0.25),
                AccessionScoreRefillsOffsetAdjuster(weight: 0.7),
                RegionAccessionScoreAdjuster(factors: ["online": 1.18]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 8943.9
        )
    }
}
