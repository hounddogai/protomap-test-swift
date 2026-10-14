import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up score calculation.
    protocol FollowUpScoreModifier {
        func describe() -> String
        func adjust(_ item: FollowUpScore, value: Double) -> Double
    }

    final class CountryFollowUpScoreAdjuster: FollowUpScoreModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: FollowUpScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentFollowUpScoreAdjuster: FollowUpScoreModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFollowUpScoreAdjuster: FollowUpScoreModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the follow up score steps in order and keeps a trace of each.
    final class FollowUpScoreEngine {
        var steps: [any FollowUpScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FollowUpScore) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [FollowUpScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFollowUpScoreEngine() -> FollowUpScoreEngine {
        return FollowUpScoreEngine(
            steps: [
                CountryFollowUpScoreAdjuster(factors: ["online": 0.7, "east": 0.99, "retail": 0.79]),
                PercentFollowUpScoreAdjuster(percent: 7.2),
                CapFollowUpScoreAdjuster(cap: 1880.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 29239.7
        )
    }
}
