import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the seasonal rounding audit calculation.
    protocol SeasonalRoundingAuditModifier {
        func describe() -> String
        func adjust(_ item: SeasonalRoundingAudit, value: Double) -> Double
    }

    final class TieredSeasonalRoundingAuditAdjuster: SeasonalRoundingAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalRoundingAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumSeasonalRoundingAuditAdjuster: SeasonalRoundingAuditModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalRoundingAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingSeasonalRoundingAuditAdjuster: SeasonalRoundingAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalRoundingAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal rounding audit steps in order and keeps a trace of each.
    final class SeasonalRoundingAuditEngine {
        var steps: [any SeasonalRoundingAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalRoundingAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalRoundingAudit) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalRoundingAuditModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalRoundingAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalRoundingAuditEngine() -> SeasonalRoundingAuditEngine {
        return SeasonalRoundingAuditEngine(
            steps: [
                TieredSeasonalRoundingAuditAdjuster(
                    bounds: [843.0, 1230.0, 3467.0, 6645.0],
                    rates: [0.87, 1.18, 1.01, 0.91]
                ),
                MinimumSeasonalRoundingAuditAdjuster(minimum: 0.9),
                RoundingSeasonalRoundingAuditAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 73740.4
        )
    }
}
