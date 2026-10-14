import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered proxy schedule calculation.
    protocol PreferenceTieredProxyScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: TieredProxySchedule, value: Double) -> Double
    }

    final class TieredTieredProxyScheduleAdjuster: PreferenceTieredProxyScheduleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredProxySchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedTieredProxyScheduleAdjuster: PreferenceTieredProxyScheduleAdjuster {
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

        func adjust(_ item: TieredProxySchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentTieredProxyScheduleAdjuster: PreferenceTieredProxyScheduleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: TieredProxySchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTieredProxyScheduleAdjuster: PreferenceTieredProxyScheduleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredProxySchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered proxy schedule steps in order and keeps a trace of each.
    final class TieredProxyScheduleEngine {
        var steps: [any PreferenceTieredProxyScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PreferenceTieredProxyScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredProxySchedule) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PreferenceTieredProxyScheduleAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredProxySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredProxyScheduleEngine(_ flags: Kit.Flags.Registry) -> TieredProxyScheduleEngine {
        return TieredProxyScheduleEngine(
            steps: [
                TieredTieredProxyScheduleAdjuster(
                    bounds: [1858.0, 3143.0, 6177.0, 8460.0],
                    rates: [1.06, 1.05, 0.88, 0.87]
                ),
                FlaggedTieredProxyScheduleAdjuster(flags: flags, flag: "tiered-proxy-schedule-batched", percent: -9.4),
                SegmentTieredProxyScheduleAdjuster(factors: ["online": 1.39, "central": 0.93, "east": 1.4]),
                CapTieredProxyScheduleAdjuster(cap: 24554.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 27164.8
        )
    }
}
