import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the global inventory window calculation.
    protocol GlobalInventoryWindowFactor {
        func describe() -> String
        func adjust(_ item: GlobalInventoryWindow, value: Double) -> Double
    }

    final class CapGlobalInventoryWindowAdjuster: GlobalInventoryWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalInventoryWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedGlobalInventoryWindowAdjuster: GlobalInventoryWindowFactor {
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

        func adjust(_ item: GlobalInventoryWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalInventoryWindowAdjuster: GlobalInventoryWindowFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalInventoryWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalInventoryWindowAdjuster: GlobalInventoryWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalInventoryWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global inventory window steps in order and keeps a trace of each.
    final class GlobalInventoryWindowEngine {
        var steps: [any GlobalInventoryWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalInventoryWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalInventoryWindow) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalInventoryWindowFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalInventoryWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalInventoryWindowEngine(_ flags: Kit.Flags.Registry) -> GlobalInventoryWindowEngine {
        return GlobalInventoryWindowEngine(
            steps: [
                CapGlobalInventoryWindowAdjuster(cap: 9408.0),
                FlaggedGlobalInventoryWindowAdjuster(
                    flags: flags,
                    flag: "global-inventory-window-fallback",
                    percent: -6.9
                ),
                TieredGlobalInventoryWindowAdjuster(
                    bounds: [1697.0, 2853.0, 6271.0, 9499.0],
                    rates: [0.91, 1.03, 1.14, 0.84]
                ),
                PercentGlobalInventoryWindowAdjuster(percent: -15.1),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 73622.2
        )
    }
}
