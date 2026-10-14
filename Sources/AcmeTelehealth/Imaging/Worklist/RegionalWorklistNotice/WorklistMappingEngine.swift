import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist mapping calculation.
    protocol WorklistMappingStep {
        func describe() -> String
        func adjust(_ item: WorklistMapping, value: Double) -> Double
    }

    final class MinimumWorklistMappingAdjuster: WorklistMappingStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WorklistMappingFloorValueOffsetAdjuster: WorklistMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: WorklistMapping, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class NameWorklistMappingAdjuster: WorklistMappingStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WorklistMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedWorklistMappingAdjuster: WorklistMappingStep {
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

        func adjust(_ item: WorklistMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWorklistMappingAdjuster: WorklistMappingStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWorklistMappingAdjuster: WorklistMappingStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the worklist mapping steps in order and keeps a trace of each.
    final class WorklistMappingEngine {
        var steps: [any WorklistMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WorklistMapping) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WorklistMappingStep = steps[index]
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

        func evaluateAll(_ items: [WorklistMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWorklistMappingEngine(_ flags: Kit.Flags.Registry) -> WorklistMappingEngine {
        return WorklistMappingEngine(
            steps: [
                MinimumWorklistMappingAdjuster(minimum: 2.3),
                WorklistMappingFloorValueOffsetAdjuster(weight: 0.48),
                NameWorklistMappingAdjuster(factors: ["south": 1.34, "retail": 1.24]),
                FlaggedWorklistMappingAdjuster(flags: flags, flag: "worklist-mapping-primary", percent: -9.7),
                TieredWorklistMappingAdjuster(
                    bounds: [2528.0, 5505.0, 5821.0, 7733.0],
                    rates: [1.15, 0.99, 0.81, 1.0]
                ),
                RoundingWorklistMappingAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 57924.2
        )
    }
}
