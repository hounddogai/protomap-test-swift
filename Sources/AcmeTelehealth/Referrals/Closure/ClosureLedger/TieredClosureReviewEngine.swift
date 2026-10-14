import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered closure review calculation.
    protocol TieredClosureReviewAdjuster {
        func describe() -> String
        func adjust(_ item: TieredClosureReview, value: Double) -> Double
    }

    final class MinimumTieredClosureReviewAdjuster: TieredClosureReviewAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredClosureReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapTieredClosureReviewAdjuster: TieredClosureReviewAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredClosureReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredClosureReviewRevisionOffsetAdjuster: TieredClosureReviewAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: TieredClosureReview, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class NameTieredClosureReviewAdjuster: TieredClosureReviewAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TieredClosureReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentTieredClosureReviewAdjuster: TieredClosureReviewAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredClosureReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered closure review steps in order and keeps a trace of each.
    final class TieredClosureReviewEngine {
        var steps: [any TieredClosureReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredClosureReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredClosureReview) -> Double {
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

        func evaluateAll(_ items: [TieredClosureReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredClosureReviewEngine() -> TieredClosureReviewEngine {
        return TieredClosureReviewEngine(
            steps: [
                MinimumTieredClosureReviewAdjuster(minimum: 21.1),
                CapTieredClosureReviewAdjuster(cap: 12985.0),
                TieredClosureReviewRevisionOffsetAdjuster(weight: 0.92),
                NameTieredClosureReviewAdjuster(factors: ["north": 1.06, "east": 0.96, "online": 1.36]),
                PercentTieredClosureReviewAdjuster(percent: -19.5),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 68286.1
        )
    }
}
