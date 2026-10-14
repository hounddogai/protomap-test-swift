import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense rollup calculation.
    protocol DispenseRollupFactor {
        func describe() -> String
        func adjust(_ item: DispenseRollup, value: Double) -> Double
    }

    final class CapDispenseRollupAdjuster: DispenseRollupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class DispenseRollupCopayOffsetAdjuster: DispenseRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: DispenseRollup, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class MinimumDispenseRollupAdjuster: DispenseRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionDispenseRollupAdjuster: DispenseRollupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: DispenseRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDispenseRollupAdjuster: DispenseRollupFactor {
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

        func adjust(_ item: DispenseRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the dispense rollup steps in order and keeps a trace of each.
    final class DispenseRollupEngine {
        var steps: [any DispenseRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DispenseRollup) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseRollupFactor = steps[index]
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

        func evaluateAll(_ items: [DispenseRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDispenseRollupEngine(_ flags: Kit.Flags.Registry) -> DispenseRollupEngine {
        return DispenseRollupEngine(
            steps: [
                CapDispenseRollupAdjuster(cap: 8243.0),
                DispenseRollupCopayOffsetAdjuster(weight: 0.93),
                MinimumDispenseRollupAdjuster(minimum: 27.1),
                RegionDispenseRollupAdjuster(factors: ["online": 0.87, "east": 1.12, "south": 1.32]),
                FlaggedDispenseRollupAdjuster(flags: flags, flag: "dispense-rollup-legacy", percent: 2.4),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 58046.5
        )
    }
}
