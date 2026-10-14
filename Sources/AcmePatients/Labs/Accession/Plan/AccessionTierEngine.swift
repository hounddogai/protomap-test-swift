import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession tier calculation.
    protocol AccessionTierFactor {
        func describe() -> String
        func adjust(_ item: AccessionTier, value: Double) -> Double
    }

    final class SourceAccessionTierAdjuster: AccessionTierFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: AccessionTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAccessionTierAdjuster: AccessionTierFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAccessionTierAdjuster: AccessionTierFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAccessionTierAdjuster: AccessionTierFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the accession tier steps in order and keeps a trace of each.
    final class AccessionTierEngine {
        var steps: [any AccessionTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AccessionTier) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionTierFactor = steps[index]
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

        func evaluateAll(_ items: [AccessionTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAccessionTierEngine() -> AccessionTierEngine {
        return AccessionTierEngine(
            steps: [
                SourceAccessionTierAdjuster(factors: ["west": 1.0, "online": 1.05]),
                MinimumAccessionTierAdjuster(minimum: 10.1),
                RoundingAccessionTierAdjuster(step: 1.0),
                PercentAccessionTierAdjuster(percent: -6.6),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 30406.2
        )
    }
}
