import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback rounding slot calculation.
    protocol FallbackRoundingSlotFactor {
        func describe() -> String
        func adjust(_ item: FallbackRoundingSlot, value: Double) -> Double
    }

    final class PercentFallbackRoundingSlotAdjuster: FallbackRoundingSlotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackRoundingSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackRoundingSlotAdjuster: FallbackRoundingSlotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackRoundingSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFallbackRoundingSlotAdjuster: FallbackRoundingSlotFactor {
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

        func adjust(_ item: FallbackRoundingSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFallbackRoundingSlotAdjuster: FallbackRoundingSlotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackRoundingSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameFallbackRoundingSlotAdjuster: FallbackRoundingSlotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackRoundingSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackRoundingSlotAdjuster: FallbackRoundingSlotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackRoundingSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback rounding slot steps in order and keeps a trace of each.
    final class FallbackRoundingSlotEngine {
        var steps: [any FallbackRoundingSlotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackRoundingSlotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackRoundingSlot) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackRoundingSlotFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackRoundingSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackRoundingSlotEngine(_ flags: Kit.Flags.Registry) -> FallbackRoundingSlotEngine {
        return FallbackRoundingSlotEngine(
            steps: [
                PercentFallbackRoundingSlotAdjuster(percent: -17.9),
                CapFallbackRoundingSlotAdjuster(cap: 12209.0),
                FlaggedFallbackRoundingSlotAdjuster(
                    flags: flags,
                    flag: "fallback-rounding-slot-strict",
                    percent: -1.8
                ),
                TieredFallbackRoundingSlotAdjuster(bounds: [8048.0, 8517.0], rates: [0.96, 1.09]),
                NameFallbackRoundingSlotAdjuster(factors: ["east": 1.34, "south": 1.21, "online": 0.71]),
                MinimumFallbackRoundingSlotAdjuster(minimum: 28.0),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 25585.7
        )
    }
}
