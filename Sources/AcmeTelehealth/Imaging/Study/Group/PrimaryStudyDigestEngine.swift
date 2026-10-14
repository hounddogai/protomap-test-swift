import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary study digest calculation.
    protocol PrimaryStudyDigestAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryStudyDigest, value: Double) -> Double
    }

    final class TieredPrimaryStudyDigestAdjuster: PrimaryStudyDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryStudyDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrimaryStudyDigestAdjuster: PrimaryStudyDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryStudyDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PrimaryStudyDigestBudgetOffsetAdjuster: PrimaryStudyDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: PrimaryStudyDigest, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class CapPrimaryStudyDigestAdjuster: PrimaryStudyDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryStudyDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPrimaryStudyDigestAdjuster: PrimaryStudyDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryStudyDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary study digest steps in order and keeps a trace of each.
    final class PrimaryStudyDigestEngine {
        var steps: [any PrimaryStudyDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryStudyDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryStudyDigest) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [PrimaryStudyDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryStudyDigestEngine() -> PrimaryStudyDigestEngine {
        return PrimaryStudyDigestEngine(
            steps: [
                TieredPrimaryStudyDigestAdjuster(bounds: [2416.0, 2690.0], rates: [0.81, 1.14]),
                RoundingPrimaryStudyDigestAdjuster(step: 0.5),
                PrimaryStudyDigestBudgetOffsetAdjuster(weight: 1.95),
                CapPrimaryStudyDigestAdjuster(cap: 22291.0),
                MinimumPrimaryStudyDigestAdjuster(minimum: 13.3),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 96593.4
        )
    }
}
