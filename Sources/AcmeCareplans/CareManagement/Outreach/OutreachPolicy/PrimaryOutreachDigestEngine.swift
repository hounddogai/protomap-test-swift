import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the primary outreach digest calculation.
    protocol PrimaryOutreachDigestAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryOutreachDigest, value: Double) -> Double
    }

    final class PrimaryOutreachDigestQuantityOffsetAdjuster: PrimaryOutreachDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: PrimaryOutreachDigest, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class RoundingPrimaryOutreachDigestAdjuster: PrimaryOutreachDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryOutreachDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPrimaryOutreachDigestAdjuster: PrimaryOutreachDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryOutreachDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPrimaryOutreachDigestAdjuster: PrimaryOutreachDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryOutreachDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary outreach digest steps in order and keeps a trace of each.
    final class PrimaryOutreachDigestEngine {
        var steps: [any PrimaryOutreachDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryOutreachDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryOutreachDigest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryOutreachDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryOutreachDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryOutreachDigestEngine() -> PrimaryOutreachDigestEngine {
        return PrimaryOutreachDigestEngine(
            steps: [
                PrimaryOutreachDigestQuantityOffsetAdjuster(weight: 1.95),
                RoundingPrimaryOutreachDigestAdjuster(step: 1.0),
                MinimumPrimaryOutreachDigestAdjuster(minimum: 5.3),
                TieredPrimaryOutreachDigestAdjuster(
                    bounds: [5400.0, 7321.0, 8720.0, 9159.0],
                    rates: [0.9, 0.9, 1.12, 1.01]
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 80746.5
        )
    }
}
