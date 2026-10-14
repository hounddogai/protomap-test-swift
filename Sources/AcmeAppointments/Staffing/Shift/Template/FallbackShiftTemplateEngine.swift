import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback shift template calculation.
    protocol FallbackShiftTemplateFactor {
        func describe() -> String
        func adjust(_ item: FallbackShiftTemplate, value: Double) -> Double
    }

    final class CapFallbackShiftTemplateAdjuster: FallbackShiftTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackShiftTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFallbackShiftTemplateAdjuster: FallbackShiftTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackShiftTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingFallbackShiftTemplateAdjuster: FallbackShiftTemplateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackShiftTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedFallbackShiftTemplateAdjuster: FallbackShiftTemplateFactor {
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

        func adjust(_ item: FallbackShiftTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackShiftTemplateCeilingOffsetAdjuster: FallbackShiftTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: FallbackShiftTemplate, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the fallback shift template steps in order and keeps a trace of each.
    final class FallbackShiftTemplateEngine {
        var steps: [any FallbackShiftTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackShiftTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackShiftTemplate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackShiftTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackShiftTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackShiftTemplateEngine(_ flags: Kit.Flags.Registry) -> FallbackShiftTemplateEngine {
        return FallbackShiftTemplateEngine(
            steps: [
                CapFallbackShiftTemplateAdjuster(cap: 23692.0),
                TieredFallbackShiftTemplateAdjuster(
                    bounds: [4291.0, 5160.0, 5278.0, 6566.0],
                    rates: [1.09, 0.82, 1.14, 1.15]
                ),
                RoundingFallbackShiftTemplateAdjuster(step: 0.05),
                FlaggedFallbackShiftTemplateAdjuster(
                    flags: flags,
                    flag: "fallback-shift-template-pending",
                    percent: 1.9
                ),
                FallbackShiftTemplateCeilingOffsetAdjuster(weight: 1.9),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 19763.5
        )
    }
}
