import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier mapping calculation.
    protocol CourierMappingStep {
        func describe() -> String
        func adjust(_ item: CourierMapping, value: Double) -> Double
    }

    final class FlaggedCourierMappingAdjuster: CourierMappingStep {
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

        func adjust(_ item: CourierMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCourierMappingAdjuster: CourierMappingStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCourierMappingAdjuster: CourierMappingStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapCourierMappingAdjuster: CourierMappingStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCourierMappingAdjuster: CourierMappingStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the courier mapping steps in order and keeps a trace of each.
    final class CourierMappingEngine {
        var steps: [any CourierMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CourierMapping) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CourierMappingStep = steps[index]
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

        func evaluateAll(_ items: [CourierMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCourierMappingEngine(_ flags: Kit.Flags.Registry) -> CourierMappingEngine {
        return CourierMappingEngine(
            steps: [
                FlaggedCourierMappingAdjuster(flags: flags, flag: "courier-mapping-global", percent: -4.5),
                MinimumCourierMappingAdjuster(minimum: 25.3),
                RoundingCourierMappingAdjuster(step: 5.0),
                CapCourierMappingAdjuster(cap: 1323.0),
                TieredCourierMappingAdjuster(
                    bounds: [3117.0, 4887.0, 5704.0, 9438.0],
                    rates: [0.91, 0.86, 1.12, 0.86]
                ),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 7330.5
        )
    }
}
