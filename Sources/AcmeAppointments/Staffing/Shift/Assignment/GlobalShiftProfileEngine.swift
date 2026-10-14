import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global shift profile calculation.
    protocol GlobalShiftProfileAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalShiftProfile, value: Double) -> Double
    }

    final class CapGlobalShiftProfileAdjuster: GlobalShiftProfileAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalShiftProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GlobalShiftProfileStartsAtOffsetAdjuster: GlobalShiftProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: GlobalShiftProfile, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class FlaggedGlobalShiftProfileAdjuster: GlobalShiftProfileAdjuster {
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

        func adjust(_ item: GlobalShiftProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalShiftProfileAdjuster: GlobalShiftProfileAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalShiftProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalShiftProfileAdjuster: GlobalShiftProfileAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalShiftProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global shift profile steps in order and keeps a trace of each.
    final class GlobalShiftProfileEngine {
        var steps: [any GlobalShiftProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalShiftProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalShiftProfile) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [GlobalShiftProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalShiftProfileEngine(_ flags: Kit.Flags.Registry) -> GlobalShiftProfileEngine {
        return GlobalShiftProfileEngine(
            steps: [
                CapGlobalShiftProfileAdjuster(cap: 9372.0),
                GlobalShiftProfileStartsAtOffsetAdjuster(weight: 0.13),
                FlaggedGlobalShiftProfileAdjuster(flags: flags, flag: "global-shift-profile-manual", percent: -4.5),
                TieredGlobalShiftProfileAdjuster(bounds: [2182.0, 2727.0, 3620.0], rates: [1.06, 0.86, 1.17]),
                PercentGlobalShiftProfileAdjuster(percent: -5.3),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 22842.1
        )
    }
}
