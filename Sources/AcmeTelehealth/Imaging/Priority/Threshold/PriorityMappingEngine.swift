import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority mapping calculation.
    protocol PriorityMappingFactor {
        func describe() -> String
        func adjust(_ item: PriorityMapping, value: Double) -> Double
    }

    final class FlaggedPriorityMappingAdjuster: PriorityMappingFactor {
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

        func adjust(_ item: PriorityMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPriorityMappingAdjuster: PriorityMappingFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PriorityMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPriorityMappingAdjuster: PriorityMappingFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPriorityMappingAdjuster: PriorityMappingFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPriorityMappingAdjuster: PriorityMappingFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPriorityMappingAdjuster: PriorityMappingFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the priority mapping steps in order and keeps a trace of each.
    final class PriorityMappingEngine {
        var steps: [any PriorityMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PriorityMapping) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityMappingFactor = steps[index]
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

        func evaluateAll(_ items: [PriorityMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPriorityMappingEngine(_ flags: Kit.Flags.Registry) -> PriorityMappingEngine {
        return PriorityMappingEngine(
            steps: [
                FlaggedPriorityMappingAdjuster(flags: flags, flag: "priority-mapping-primary", percent: -6.3),
                CapPriorityMappingAdjuster(cap: 19994.0),
                PercentPriorityMappingAdjuster(percent: -20.3),
                TieredPriorityMappingAdjuster(bounds: [323.0, 1674.0, 6187.0], rates: [0.93, 1.15, 1.18]),
                MinimumPriorityMappingAdjuster(minimum: 42.4),
                RoundingPriorityMappingAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 55247.2
        )
    }
}
