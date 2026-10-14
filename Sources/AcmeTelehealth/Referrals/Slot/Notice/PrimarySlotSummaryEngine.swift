import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary slot summary calculation.
    protocol PrimarySlotSummaryFactor {
        func describe() -> String
        func adjust(_ item: PrimarySlotSummary, value: Double) -> Double
    }

    final class CapPrimarySlotSummaryAdjuster: PrimarySlotSummaryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimarySlotSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPrimarySlotSummaryAdjuster: PrimarySlotSummaryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimarySlotSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimarySlotSummaryAdjuster: PrimarySlotSummaryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimarySlotSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PrimarySlotSummaryDiscountOffsetAdjuster: PrimarySlotSummaryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: PrimarySlotSummary, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class MinimumPrimarySlotSummaryAdjuster: PrimarySlotSummaryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimarySlotSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary slot summary steps in order and keeps a trace of each.
    final class PrimarySlotSummaryEngine {
        var steps: [any PrimarySlotSummaryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimarySlotSummaryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimarySlotSummary) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimarySlotSummaryFactor = steps[index]
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

        func evaluateAll(_ items: [PrimarySlotSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimarySlotSummaryEngine() -> PrimarySlotSummaryEngine {
        return PrimarySlotSummaryEngine(
            steps: [
                CapPrimarySlotSummaryAdjuster(cap: 42654.0),
                PercentPrimarySlotSummaryAdjuster(percent: -17.0),
                RoundingPrimarySlotSummaryAdjuster(step: 5.0),
                PrimarySlotSummaryDiscountOffsetAdjuster(weight: 0.93),
                MinimumPrimarySlotSummaryAdjuster(minimum: 48.1),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 5377.7
        )
    }
}
