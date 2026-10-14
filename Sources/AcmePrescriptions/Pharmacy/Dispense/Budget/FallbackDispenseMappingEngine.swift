import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the fallback dispense mapping calculation.
    protocol FallbackDispenseMappingAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackDispenseMapping, value: Double) -> Double
    }

    final class RegionFallbackDispenseMappingAdjuster: FallbackDispenseMappingAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: FallbackDispenseMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FallbackDispenseMappingMaximumOffsetAdjuster: FallbackDispenseMappingAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: FallbackDispenseMapping, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class PercentFallbackDispenseMappingAdjuster: FallbackDispenseMappingAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackDispenseMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFallbackDispenseMappingAdjuster: FallbackDispenseMappingAdjuster {
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

        func adjust(_ item: FallbackDispenseMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackDispenseMappingAdjuster: FallbackDispenseMappingAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackDispenseMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback dispense mapping steps in order and keeps a trace of each.
    final class FallbackDispenseMappingEngine {
        var steps: [any FallbackDispenseMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackDispenseMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackDispenseMapping) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackDispenseMappingAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackDispenseMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackDispenseMappingEngine(_ flags: Kit.Flags.Registry) -> FallbackDispenseMappingEngine {
        return FallbackDispenseMappingEngine(
            steps: [
                RegionFallbackDispenseMappingAdjuster(factors: ["north": 1.15, "central": 1.22]),
                FallbackDispenseMappingMaximumOffsetAdjuster(weight: 0.49),
                PercentFallbackDispenseMappingAdjuster(percent: -21.7),
                FlaggedFallbackDispenseMappingAdjuster(
                    flags: flags,
                    flag: "fallback-dispense-mapping-legacy",
                    percent: 5.0
                ),
                CapFallbackDispenseMappingAdjuster(cap: 48903.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 47790.0
        )
    }
}
