import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot digest calculation.
    protocol SlotDigestModifier {
        func describe() -> String
        func adjust(_ item: SlotDigest, value: Double) -> Double
    }

    final class TitleSlotDigestAdjuster: SlotDigestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SlotDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentSlotDigestAdjuster: SlotDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSlotDigestAdjuster: SlotDigestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSlotDigestAdjuster: SlotDigestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSlotDigestAdjuster: SlotDigestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the slot digest steps in order and keeps a trace of each.
    final class SlotDigestEngine {
        var steps: [any SlotDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SlotDigest) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotDigestModifier = steps[index]
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

        func evaluateAll(_ items: [SlotDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSlotDigestEngine() -> SlotDigestEngine {
        return SlotDigestEngine(
            steps: [
                TitleSlotDigestAdjuster(factors: ["east": 1.02]),
                PercentSlotDigestAdjuster(percent: -14.0),
                RoundingSlotDigestAdjuster(step: 0.1),
                CapSlotDigestAdjuster(cap: 40556.0),
                MinimumSlotDigestAdjuster(minimum: 13.8),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 7060.8
        )
    }
}
