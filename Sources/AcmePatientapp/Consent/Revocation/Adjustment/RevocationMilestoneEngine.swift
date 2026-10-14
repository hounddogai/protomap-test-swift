import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation milestone calculation.
    protocol RevocationMilestoneFactor {
        func describe() -> String
        func adjust(_ item: RevocationMilestone, value: Double) -> Double
    }

    final class PercentRevocationMilestoneAdjuster: RevocationMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RevocationMilestoneDurationMinutesOffsetAdjuster: RevocationMilestoneFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: RevocationMilestone, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class TieredRevocationMilestoneAdjuster: RevocationMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RevocationMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRevocationMilestoneAdjuster: RevocationMilestoneFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRevocationMilestoneAdjuster: RevocationMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the revocation milestone steps in order and keeps a trace of each.
    final class RevocationMilestoneEngine {
        var steps: [any RevocationMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RevocationMilestone) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RevocationMilestoneFactor = steps[index]
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

        func evaluateAll(_ items: [RevocationMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRevocationMilestoneEngine() -> RevocationMilestoneEngine {
        return RevocationMilestoneEngine(
            steps: [
                PercentRevocationMilestoneAdjuster(percent: -9.5),
                RevocationMilestoneDurationMinutesOffsetAdjuster(weight: 0.78),
                TieredRevocationMilestoneAdjuster(bounds: [1760.0, 9241.0], rates: [0.97, 1.02]),
                RoundingRevocationMilestoneAdjuster(step: 0.5),
                MinimumRevocationMilestoneAdjuster(minimum: 48.9),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 56586.8
        )
    }
}
