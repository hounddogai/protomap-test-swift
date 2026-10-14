import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach slot calculation.
    protocol OutreachSlotModifier {
        func describe() -> String
        func adjust(_ item: OutreachSlot, value: Double) -> Double
    }

    final class PercentOutreachSlotAdjuster: OutreachSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OutreachSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapOutreachSlotAdjuster: OutreachSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OutreachSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumOutreachSlotAdjuster: OutreachSlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameOutreachSlotAdjuster: OutreachSlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: OutreachSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingOutreachSlotAdjuster: OutreachSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class OutreachSlotVisitMinutesOffsetAdjuster: OutreachSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: OutreachSlot, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    /// Runs the outreach slot steps in order and keeps a trace of each.
    final class OutreachSlotEngine {
        var steps: [any OutreachSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OutreachSlot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any OutreachSlotModifier = steps[index]
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

        func evaluateAll(_ items: [OutreachSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOutreachSlotEngine() -> OutreachSlotEngine {
        return OutreachSlotEngine(
            steps: [
                PercentOutreachSlotAdjuster(percent: -0.5),
                CapOutreachSlotAdjuster(cap: 36462.0),
                MinimumOutreachSlotAdjuster(minimum: 7.7),
                NameOutreachSlotAdjuster(factors: ["central": 0.84]),
                RoundingOutreachSlotAdjuster(step: 0.05),
                OutreachSlotVisitMinutesOffsetAdjuster(weight: 1.77),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 87037.5
        )
    }
}
