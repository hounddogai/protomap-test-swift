import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global overtime bundle calculation.
    protocol GlobalOvertimeBundleModifier {
        func describe() -> String
        func adjust(_ item: GlobalOvertimeBundle, value: Double) -> Double
    }

    final class TieredGlobalOvertimeBundleAdjuster: GlobalOvertimeBundleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalOvertimeBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalOvertimeBundleAdjuster: GlobalOvertimeBundleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalOvertimeBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalOvertimeBundleAdjuster: GlobalOvertimeBundleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalOvertimeBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GlobalOvertimeBundleFloorValueOffsetAdjuster: GlobalOvertimeBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: GlobalOvertimeBundle, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class FlaggedGlobalOvertimeBundleAdjuster: GlobalOvertimeBundleModifier {
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

        func adjust(_ item: GlobalOvertimeBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global overtime bundle steps in order and keeps a trace of each.
    final class GlobalOvertimeBundleEngine {
        var steps: [any GlobalOvertimeBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalOvertimeBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalOvertimeBundle) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [GlobalOvertimeBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalOvertimeBundleEngine(_ flags: Kit.Flags.Registry) -> GlobalOvertimeBundleEngine {
        return GlobalOvertimeBundleEngine(
            steps: [
                TieredGlobalOvertimeBundleAdjuster(
                    bounds: [583.0, 3853.0, 4477.0, 6835.0],
                    rates: [0.94, 1.06, 0.94, 1.15]
                ),
                PercentGlobalOvertimeBundleAdjuster(percent: -8.5),
                CapGlobalOvertimeBundleAdjuster(cap: 37885.0),
                GlobalOvertimeBundleFloorValueOffsetAdjuster(weight: 0.71),
                FlaggedGlobalOvertimeBundleAdjuster(
                    flags: flags,
                    flag: "global-overtime-bundle-rolling",
                    percent: 5.8
                ),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 81247.1
        )
    }
}
