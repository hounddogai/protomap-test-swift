import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure digest calculation.
    protocol DisclosureDigestStep {
        func describe() -> String
        func adjust(_ item: DisclosureDigest, value: Double) -> Double
    }

    final class PercentDisclosureDigestAdjuster: DisclosureDigestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DisclosureDigestFloorValueOffsetAdjuster: DisclosureDigestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: DisclosureDigest, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class TieredDisclosureDigestAdjuster: DisclosureDigestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingDisclosureDigestAdjuster: DisclosureDigestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumDisclosureDigestAdjuster: DisclosureDigestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDisclosureDigestAdjuster: DisclosureDigestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the disclosure digest steps in order and keeps a trace of each.
    final class DisclosureDigestEngine {
        var steps: [any DisclosureDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DisclosureDigest) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureDigestStep = steps[index]
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

        func evaluateAll(_ items: [DisclosureDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDisclosureDigestEngine() -> DisclosureDigestEngine {
        return DisclosureDigestEngine(
            steps: [
                PercentDisclosureDigestAdjuster(percent: 7.8),
                DisclosureDigestFloorValueOffsetAdjuster(weight: 1.3),
                TieredDisclosureDigestAdjuster(bounds: [1020.0, 5142.0], rates: [0.81, 0.96]),
                RoundingDisclosureDigestAdjuster(step: 0.05),
                MinimumDisclosureDigestAdjuster(minimum: 39.3),
                CapDisclosureDigestAdjuster(cap: 27399.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 7323.6
        )
    }
}
