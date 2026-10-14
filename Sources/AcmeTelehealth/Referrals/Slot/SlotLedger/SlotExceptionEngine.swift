import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot exception calculation.
    protocol SlotExceptionFactor {
        func describe() -> String
        func adjust(_ item: SlotException, value: Double) -> Double
    }

    final class SlotExceptionVersionOffsetAdjuster: SlotExceptionFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: SlotException, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class RoundingSlotExceptionAdjuster: SlotExceptionFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSlotExceptionAdjuster: SlotExceptionFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSlotExceptionAdjuster: SlotExceptionFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSlotExceptionAdjuster: SlotExceptionFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the slot exception steps in order and keeps a trace of each.
    final class SlotExceptionEngine {
        var steps: [any SlotExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SlotException) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [SlotException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSlotExceptionEngine() -> SlotExceptionEngine {
        return SlotExceptionEngine(
            steps: [
                SlotExceptionVersionOffsetAdjuster(weight: 0.76),
                RoundingSlotExceptionAdjuster(step: 1.0),
                CapSlotExceptionAdjuster(cap: 32363.0),
                MinimumSlotExceptionAdjuster(minimum: 43.6),
                PercentSlotExceptionAdjuster(percent: 14.8),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 38692.9
        )
    }
}
