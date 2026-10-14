import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the legacy remittance milestone calculation.
    protocol LegacyRemittanceMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyRemittanceMilestone, value: Double) -> Double
    }

    final class MinimumLegacyRemittanceMilestoneAdjuster: LegacyRemittanceMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyRemittanceMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLegacyRemittanceMilestoneAdjuster: LegacyRemittanceMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyRemittanceMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LegacyRemittanceMilestoneAcuityOffsetAdjuster: LegacyRemittanceMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: LegacyRemittanceMilestone, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the legacy remittance milestone steps in order and keeps a trace of each.
    final class LegacyRemittanceMilestoneEngine {
        var steps: [any LegacyRemittanceMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyRemittanceMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyRemittanceMilestone) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyRemittanceMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [LegacyRemittanceMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyRemittanceMilestoneEngine() -> LegacyRemittanceMilestoneEngine {
        return LegacyRemittanceMilestoneEngine(
            steps: [
                MinimumLegacyRemittanceMilestoneAdjuster(minimum: 10.1),
                RoundingLegacyRemittanceMilestoneAdjuster(step: 1.0),
                LegacyRemittanceMilestoneAcuityOffsetAdjuster(weight: 0.38),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 74452.8
        )
    }
}
