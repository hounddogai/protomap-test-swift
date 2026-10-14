import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict care protocol mapping calculation.
    protocol StrictCareProtocolMappingFactor {
        func describe() -> String
        func adjust(_ item: StrictCareProtocolMapping, value: Double) -> Double
    }

    final class MinimumStrictCareProtocolMappingAdjuster: StrictCareProtocolMappingFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictCareProtocolMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredStrictCareProtocolMappingAdjuster: StrictCareProtocolMappingFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictCareProtocolMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedStrictCareProtocolMappingAdjuster: StrictCareProtocolMappingFactor {
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

        func adjust(_ item: StrictCareProtocolMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStrictCareProtocolMappingAdjuster: StrictCareProtocolMappingFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictCareProtocolMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StrictCareProtocolMappingBudgetOffsetAdjuster: StrictCareProtocolMappingFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: StrictCareProtocolMapping, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class CapStrictCareProtocolMappingAdjuster: StrictCareProtocolMappingFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictCareProtocolMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict care protocol mapping steps in order and keeps a trace of each.
    final class StrictCareProtocolMappingEngine {
        var steps: [any StrictCareProtocolMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCareProtocolMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictCareProtocolMapping) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictCareProtocolMappingFactor = steps[index]
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

        func evaluateAll(_ items: [StrictCareProtocolMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictCareProtocolMappingEngine(_ flags: Kit.Flags.Registry) -> StrictCareProtocolMappingEngine {
        return StrictCareProtocolMappingEngine(
            steps: [
                MinimumStrictCareProtocolMappingAdjuster(minimum: 39.6),
                TieredStrictCareProtocolMappingAdjuster(bounds: [1590.0, 9458.0], rates: [0.84, 1.08]),
                FlaggedStrictCareProtocolMappingAdjuster(
                    flags: flags,
                    flag: "strict-care-protocol-mapping-manual",
                    percent: -1.6
                ),
                RoundingStrictCareProtocolMappingAdjuster(step: 0.5),
                StrictCareProtocolMappingBudgetOffsetAdjuster(weight: 0.02),
                CapStrictCareProtocolMappingAdjuster(cap: 39843.0),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 36207.6
        )
    }
}
