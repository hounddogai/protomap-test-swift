import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the legacy assessment rollup calculation.
    protocol LegacyAssessmentRollupFactor {
        func describe() -> String
        func adjust(_ item: LegacyAssessmentRollup, value: Double) -> Double
    }

    final class RoundingLegacyAssessmentRollupAdjuster: LegacyAssessmentRollupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyAssessmentRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLegacyAssessmentRollupAdjuster: LegacyAssessmentRollupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyAssessmentRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLegacyAssessmentRollupAdjuster: LegacyAssessmentRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyAssessmentRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LegacyAssessmentRollupWeightOffsetAdjuster: LegacyAssessmentRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: LegacyAssessmentRollup, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TieredLegacyAssessmentRollupAdjuster: LegacyAssessmentRollupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyAssessmentRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy assessment rollup steps in order and keeps a trace of each.
    final class LegacyAssessmentRollupEngine {
        var steps: [any LegacyAssessmentRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAssessmentRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyAssessmentRollup) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [LegacyAssessmentRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyAssessmentRollupEngine() -> LegacyAssessmentRollupEngine {
        return LegacyAssessmentRollupEngine(
            steps: [
                RoundingLegacyAssessmentRollupAdjuster(step: 1.0),
                CapLegacyAssessmentRollupAdjuster(cap: 24717.0),
                MinimumLegacyAssessmentRollupAdjuster(minimum: 23.3),
                LegacyAssessmentRollupWeightOffsetAdjuster(weight: 0.08),
                TieredLegacyAssessmentRollupAdjuster(bounds: [1760.0, 5566.0, 5693.0], rates: [0.9, 1.09, 0.95]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 14342.5
        )
    }
}
