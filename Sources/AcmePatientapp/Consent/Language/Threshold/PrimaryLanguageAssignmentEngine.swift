import AcmePlatform
import Foundation

extension Consent {
    /// One step of the primary language assignment calculation.
    protocol PrimaryLanguageAssignmentStep {
        func describe() -> String
        func adjust(_ item: PrimaryLanguageAssignment, value: Double) -> Double
    }

    final class PrimaryLanguageAssignmentThresholdOffsetAdjuster: PrimaryLanguageAssignmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: PrimaryLanguageAssignment, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class TieredPrimaryLanguageAssignmentAdjuster: PrimaryLanguageAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryLanguageAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPrimaryLanguageAssignmentAdjuster: PrimaryLanguageAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryLanguageAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary language assignment steps in order and keeps a trace of each.
    final class PrimaryLanguageAssignmentEngine {
        var steps: [any PrimaryLanguageAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryLanguageAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryLanguageAssignment) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [PrimaryLanguageAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryLanguageAssignmentEngine() -> PrimaryLanguageAssignmentEngine {
        return PrimaryLanguageAssignmentEngine(
            steps: [
                PrimaryLanguageAssignmentThresholdOffsetAdjuster(weight: 1.35),
                TieredPrimaryLanguageAssignmentAdjuster(
                    bounds: [328.0, 1861.0, 4724.0, 7483.0],
                    rates: [0.85, 0.85, 0.86, 1.06]
                ),
                MinimumPrimaryLanguageAssignmentAdjuster(minimum: 31.3),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 87922.8
        )
    }
}
