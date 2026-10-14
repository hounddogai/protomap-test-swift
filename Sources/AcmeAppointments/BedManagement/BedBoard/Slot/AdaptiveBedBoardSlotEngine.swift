import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the adaptive bed board slot calculation.
    protocol AdaptiveBedBoardSlotAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveBedBoardSlot, value: Double) -> Double
    }

    final class FlaggedAdaptiveBedBoardSlotAdjuster: AdaptiveBedBoardSlotAdjuster {
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

        func adjust(_ item: AdaptiveBedBoardSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAdaptiveBedBoardSlotAdjuster: AdaptiveBedBoardSlotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveBedBoardSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAdaptiveBedBoardSlotAdjuster: AdaptiveBedBoardSlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveBedBoardSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAdaptiveBedBoardSlotAdjuster: AdaptiveBedBoardSlotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveBedBoardSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAdaptiveBedBoardSlotAdjuster: AdaptiveBedBoardSlotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveBedBoardSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive bed board slot steps in order and keeps a trace of each.
    final class AdaptiveBedBoardSlotEngine {
        var steps: [any AdaptiveBedBoardSlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveBedBoardSlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveBedBoardSlot) -> Double {
            var current = item.weightedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [AdaptiveBedBoardSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveBedBoardSlotEngine(_ flags: Kit.Flags.Registry) -> AdaptiveBedBoardSlotEngine {
        return AdaptiveBedBoardSlotEngine(
            steps: [
                FlaggedAdaptiveBedBoardSlotAdjuster(
                    flags: flags,
                    flag: "adaptive-bed-board-slot-batched",
                    percent: -3.4
                ),
                MinimumAdaptiveBedBoardSlotAdjuster(minimum: 18.2),
                TieredAdaptiveBedBoardSlotAdjuster(
                    bounds: [176.0, 5500.0, 6620.0, 8075.0],
                    rates: [1.12, 1.02, 1.03, 0.9]
                ),
                CapAdaptiveBedBoardSlotAdjuster(cap: 31606.0),
                RoundingAdaptiveBedBoardSlotAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 60197.5
        )
    }
}
