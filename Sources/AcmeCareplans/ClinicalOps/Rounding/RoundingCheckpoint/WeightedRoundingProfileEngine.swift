import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted rounding profile calculation.
    protocol WeightedRoundingProfileFactor {
        func describe() -> String
        func adjust(_ item: WeightedRoundingProfile, value: Double) -> Double
    }

    final class WeightedRoundingProfileLimitOffsetAdjuster: WeightedRoundingProfileFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: WeightedRoundingProfile, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class MinimumWeightedRoundingProfileAdjuster: WeightedRoundingProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedRoundingProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapWeightedRoundingProfileAdjuster: WeightedRoundingProfileFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedRoundingProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentWeightedRoundingProfileAdjuster: WeightedRoundingProfileFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedRoundingProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted rounding profile steps in order and keeps a trace of each.
    final class WeightedRoundingProfileEngine {
        var steps: [any WeightedRoundingProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedRoundingProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedRoundingProfile) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [WeightedRoundingProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedRoundingProfileEngine() -> WeightedRoundingProfileEngine {
        return WeightedRoundingProfileEngine(
            steps: [
                WeightedRoundingProfileLimitOffsetAdjuster(weight: 0.96),
                MinimumWeightedRoundingProfileAdjuster(minimum: 46.4),
                CapWeightedRoundingProfileAdjuster(cap: 5727.0),
                PercentWeightedRoundingProfileAdjuster(percent: 21.8),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 76152.5
        )
    }
}
