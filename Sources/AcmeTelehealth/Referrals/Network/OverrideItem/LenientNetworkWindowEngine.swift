import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the lenient network window calculation.
    protocol LenientNetworkWindowModifier {
        func describe() -> String
        func adjust(_ item: LenientNetworkWindow, value: Double) -> Double
    }

    final class CapLenientNetworkWindowAdjuster: LenientNetworkWindowModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientNetworkWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLenientNetworkWindowAdjuster: LenientNetworkWindowModifier {
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

        func adjust(_ item: LenientNetworkWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientNetworkWindowAdjuster: LenientNetworkWindowModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientNetworkWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitLenientNetworkWindowAdjuster: LenientNetworkWindowModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: LenientNetworkWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient network window steps in order and keeps a trace of each.
    final class LenientNetworkWindowEngine {
        var steps: [any LenientNetworkWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientNetworkWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientNetworkWindow) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [LenientNetworkWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientNetworkWindowEngine(_ flags: Kit.Flags.Registry) -> LenientNetworkWindowEngine {
        return LenientNetworkWindowEngine(
            steps: [
                CapLenientNetworkWindowAdjuster(cap: 20711.0),
                FlaggedLenientNetworkWindowAdjuster(flags: flags, flag: "lenient-network-window-manual", percent: 4.0),
                TieredLenientNetworkWindowAdjuster(
                    bounds: [3132.0, 3487.0, 5108.0, 7085.0],
                    rates: [1.17, 1.02, 0.84, 0.89]
                ),
                UnitLenientNetworkWindowAdjuster(factors: ["online": 1.1, "east": 1.08]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 59144.6
        )
    }
}
