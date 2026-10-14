import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the default care protocol slot calculation.
    protocol DefaultCareProtocolSlotFactor {
        func describe() -> String
        func adjust(_ item: DefaultCareProtocolSlot, value: Double) -> Double
    }

    final class FlaggedDefaultCareProtocolSlotAdjuster: DefaultCareProtocolSlotFactor {
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

        func adjust(_ item: DefaultCareProtocolSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultCareProtocolSlotAdjuster: DefaultCareProtocolSlotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCareProtocolSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingDefaultCareProtocolSlotAdjuster: DefaultCareProtocolSlotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultCareProtocolSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumDefaultCareProtocolSlotAdjuster: DefaultCareProtocolSlotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultCareProtocolSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DefaultCareProtocolSlotEndsAtOffsetAdjuster: DefaultCareProtocolSlotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: DefaultCareProtocolSlot, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    /// Runs the default care protocol slot steps in order and keeps a trace of each.
    final class DefaultCareProtocolSlotEngine {
        var steps: [any DefaultCareProtocolSlotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCareProtocolSlotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultCareProtocolSlot) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultCareProtocolSlotFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultCareProtocolSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultCareProtocolSlotEngine(_ flags: Kit.Flags.Registry) -> DefaultCareProtocolSlotEngine {
        return DefaultCareProtocolSlotEngine(
            steps: [
                FlaggedDefaultCareProtocolSlotAdjuster(
                    flags: flags,
                    flag: "default-care-protocol-slot-adaptive",
                    percent: -9.6
                ),
                TieredDefaultCareProtocolSlotAdjuster(bounds: [6048.0, 8469.0], rates: [1.14, 1.1]),
                RoundingDefaultCareProtocolSlotAdjuster(step: 0.05),
                MinimumDefaultCareProtocolSlotAdjuster(minimum: 13.0),
                DefaultCareProtocolSlotEndsAtOffsetAdjuster(weight: 1.35),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 32717.6
        )
    }
}
