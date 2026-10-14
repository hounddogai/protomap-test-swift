import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the tiered formulary template calculation.
    protocol TieredFormularyTemplateModifier {
        func describe() -> String
        func adjust(_ item: TieredFormularyTemplate, value: Double) -> Double
    }

    final class CapTieredFormularyTemplateAdjuster: TieredFormularyTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredFormularyTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingTieredFormularyTemplateAdjuster: TieredFormularyTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredFormularyTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumTieredFormularyTemplateAdjuster: TieredFormularyTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredFormularyTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered formulary template steps in order and keeps a trace of each.
    final class TieredFormularyTemplateEngine {
        var steps: [any TieredFormularyTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredFormularyTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredFormularyTemplate) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredFormularyTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [TieredFormularyTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredFormularyTemplateEngine() -> TieredFormularyTemplateEngine {
        return TieredFormularyTemplateEngine(
            steps: [
                CapTieredFormularyTemplateAdjuster(cap: 16296.0),
                RoundingTieredFormularyTemplateAdjuster(step: 0.5),
                MinimumTieredFormularyTemplateAdjuster(minimum: 45.6),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 6788.8
        )
    }
}
