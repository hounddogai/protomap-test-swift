import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict worklist mapping calculation.
    protocol StrictWorklistMappingModifier {
        func describe() -> String
        func adjust(_ item: StrictWorklistMapping, value: Double) -> Double
    }

    final class TieredStrictWorklistMappingAdjuster: StrictWorklistMappingModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictWorklistMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingStrictWorklistMappingAdjuster: StrictWorklistMappingModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictWorklistMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStrictWorklistMappingAdjuster: StrictWorklistMappingModifier {
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

        func adjust(_ item: StrictWorklistMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict worklist mapping steps in order and keeps a trace of each.
    final class StrictWorklistMappingEngine {
        var steps: [any StrictWorklistMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictWorklistMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictWorklistMapping) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictWorklistMappingModifier = steps[index]
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

        func evaluateAll(_ items: [StrictWorklistMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictWorklistMappingEngine(_ flags: Kit.Flags.Registry) -> StrictWorklistMappingEngine {
        return StrictWorklistMappingEngine(
            steps: [
                TieredStrictWorklistMappingAdjuster(bounds: [272.0, 4946.0], rates: [0.81, 0.85]),
                RoundingStrictWorklistMappingAdjuster(step: 0.25),
                FlaggedStrictWorklistMappingAdjuster(
                    flags: flags,
                    flag: "strict-worklist-mapping-global",
                    percent: -9.4
                ),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 83706.4
        )
    }
}
