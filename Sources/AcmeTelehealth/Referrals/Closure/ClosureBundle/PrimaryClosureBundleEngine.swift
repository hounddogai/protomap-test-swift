import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary closure bundle calculation.
    protocol PrimaryClosureBundleAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryClosureBundle, value: Double) -> Double
    }

    final class RoundingPrimaryClosureBundleAdjuster: PrimaryClosureBundleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryClosureBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PrimaryClosureBundleScoreOffsetAdjuster: PrimaryClosureBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: PrimaryClosureBundle, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class PercentPrimaryClosureBundleAdjuster: PrimaryClosureBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryClosureBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryClosureBundleAdjuster: PrimaryClosureBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryClosureBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPrimaryClosureBundleAdjuster: PrimaryClosureBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryClosureBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FacilityPrimaryClosureBundleAdjuster: PrimaryClosureBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: PrimaryClosureBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary closure bundle steps in order and keeps a trace of each.
    final class PrimaryClosureBundleEngine {
        var steps: [any PrimaryClosureBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryClosureBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryClosureBundle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryClosureBundleAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryClosureBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryClosureBundleEngine() -> PrimaryClosureBundleEngine {
        return PrimaryClosureBundleEngine(
            steps: [
                RoundingPrimaryClosureBundleAdjuster(step: 0.5),
                PrimaryClosureBundleScoreOffsetAdjuster(weight: 0.37),
                PercentPrimaryClosureBundleAdjuster(percent: -18.5),
                MinimumPrimaryClosureBundleAdjuster(minimum: 36.2),
                CapPrimaryClosureBundleAdjuster(cap: 43164.0),
                FacilityPrimaryClosureBundleAdjuster(factors: ["north": 0.72, "central": 1.12]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 42315.3
        )
    }
}
