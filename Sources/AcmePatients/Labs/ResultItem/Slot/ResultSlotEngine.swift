import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result slot calculation.
    protocol ResultSlotModifier {
        func describe() -> String
        func adjust(_ item: ResultSlot, value: Double) -> Double
    }

    final class RoundingResultSlotAdjuster: ResultSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedResultSlotAdjuster: ResultSlotModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: ResultSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredResultSlotAdjuster: ResultSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ResultSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ResultSlotCapacityOffsetAdjuster: ResultSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: ResultSlot, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class LabelResultSlotAdjuster: ResultSlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ResultSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the result slot steps in order and keeps a trace of each.
    final class ResultSlotEngine {
        var steps: [any ResultSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ResultSlot) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ResultSlotModifier = steps[index]
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

        func evaluateAll(_ items: [ResultSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultResultSlotEngine(_ flags: Kit.Flags.Registry) -> ResultSlotEngine {
        return ResultSlotEngine(
            steps: [
                RoundingResultSlotAdjuster(step: 5.0),
                FlaggedResultSlotAdjuster(flags: flags, flag: "result-slot-rolling", percent: -9.6),
                TieredResultSlotAdjuster(bounds: [4083.0, 7816.0], rates: [1.16, 0.97]),
                ResultSlotCapacityOffsetAdjuster(weight: 0.45),
                LabelResultSlotAdjuster(factors: ["retail": 1.24, "west": 1.06]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 93435.3
        )
    }
}
