import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered proxy cycle calculation.
    protocol TieredProxyCycleFactor {
        func describe() -> String
        func adjust(_ item: TieredProxyCycle, value: Double) -> Double
    }

    final class NameTieredProxyCycleAdjuster: TieredProxyCycleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TieredProxyCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredProxyCycleAdjuster: TieredProxyCycleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredProxyCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentTieredProxyCycleAdjuster: TieredProxyCycleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredProxyCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredProxyCycleAdjuster: TieredProxyCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredProxyCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedTieredProxyCycleAdjuster: TieredProxyCycleFactor {
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

        func adjust(_ item: TieredProxyCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredProxyCycleAdjuster: TieredProxyCycleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredProxyCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered proxy cycle steps in order and keeps a trace of each.
    final class TieredProxyCycleEngine {
        var steps: [any TieredProxyCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredProxyCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredProxyCycle) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredProxyCycleFactor = steps[index]
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

        func evaluateAll(_ items: [TieredProxyCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredProxyCycleEngine(_ flags: Kit.Flags.Registry) -> TieredProxyCycleEngine {
        return TieredProxyCycleEngine(
            steps: [
                NameTieredProxyCycleAdjuster(factors: ["retail": 1.18, "east": 1.39, "central": 0.86]),
                TieredTieredProxyCycleAdjuster(
                    bounds: [5680.0, 6355.0, 8568.0, 8762.0],
                    rates: [1.16, 0.87, 0.95, 0.85]
                ),
                PercentTieredProxyCycleAdjuster(percent: 24.4),
                MinimumTieredProxyCycleAdjuster(minimum: 7.9),
                FlaggedTieredProxyCycleAdjuster(flags: flags, flag: "tiered-proxy-cycle-tiered", percent: 9.1),
                CapTieredProxyCycleAdjuster(cap: 6056.0),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 64219.4
        )
    }
}
