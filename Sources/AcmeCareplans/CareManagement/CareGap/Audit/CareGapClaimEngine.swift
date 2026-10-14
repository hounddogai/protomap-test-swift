import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap claim calculation.
    protocol CareGapClaimAdjuster {
        func describe() -> String
        func adjust(_ item: CareGapClaim, value: Double) -> Double
    }

    final class TieredCareGapClaimAdjuster: CareGapClaimAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCareGapClaimAdjuster: CareGapClaimAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCareGapClaimAdjuster: CareGapClaimAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CareGapClaimDurationMinutesOffsetAdjuster: CareGapClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: CareGapClaim, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    /// Runs the care gap claim steps in order and keeps a trace of each.
    final class CareGapClaimEngine {
        var steps: [any CareGapClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareGapClaim) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [CareGapClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareGapClaimEngine() -> CareGapClaimEngine {
        return CareGapClaimEngine(
            steps: [
                TieredCareGapClaimAdjuster(bounds: [5927.0, 8482.0], rates: [1.05, 1.17]),
                MinimumCareGapClaimAdjuster(minimum: 13.2),
                RoundingCareGapClaimAdjuster(step: 0.25),
                CareGapClaimDurationMinutesOffsetAdjuster(weight: 0.62),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 70983.2
        )
    }
}
