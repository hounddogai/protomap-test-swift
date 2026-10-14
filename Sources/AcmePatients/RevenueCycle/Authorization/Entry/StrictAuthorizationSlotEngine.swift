import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the strict authorization slot calculation.
    protocol StrictAuthorizationSlotAdjuster {
        func describe() -> String
        func adjust(_ item: StrictAuthorizationSlot, value: Double) -> Double
    }

    final class TieredStrictAuthorizationSlotAdjuster: StrictAuthorizationSlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictAuthorizationSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleStrictAuthorizationSlotAdjuster: StrictAuthorizationSlotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: StrictAuthorizationSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStrictAuthorizationSlotAdjuster: StrictAuthorizationSlotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictAuthorizationSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingStrictAuthorizationSlotAdjuster: StrictAuthorizationSlotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictAuthorizationSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StrictAuthorizationSlotQuantityOffsetAdjuster: StrictAuthorizationSlotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: StrictAuthorizationSlot, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class FlaggedStrictAuthorizationSlotAdjuster: StrictAuthorizationSlotAdjuster {
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

        func adjust(_ item: StrictAuthorizationSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict authorization slot steps in order and keeps a trace of each.
    final class StrictAuthorizationSlotEngine {
        var steps: [any StrictAuthorizationSlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictAuthorizationSlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictAuthorizationSlot) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [StrictAuthorizationSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictAuthorizationSlotEngine(_ flags: Kit.Flags.Registry) -> StrictAuthorizationSlotEngine {
        return StrictAuthorizationSlotEngine(
            steps: [
                TieredStrictAuthorizationSlotAdjuster(bounds: [4640.0, 6884.0, 7022.0], rates: [0.86, 0.92, 1.07]),
                TitleStrictAuthorizationSlotAdjuster(factors: ["north": 1.25, "online": 0.99, "south": 1.24]),
                CapStrictAuthorizationSlotAdjuster(cap: 39745.0),
                RoundingStrictAuthorizationSlotAdjuster(step: 1.0),
                StrictAuthorizationSlotQuantityOffsetAdjuster(weight: 1.9),
                FlaggedStrictAuthorizationSlotAdjuster(
                    flags: flags,
                    flag: "strict-authorization-slot-capped",
                    percent: 3.9
                ),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 97039.6
        )
    }
}
