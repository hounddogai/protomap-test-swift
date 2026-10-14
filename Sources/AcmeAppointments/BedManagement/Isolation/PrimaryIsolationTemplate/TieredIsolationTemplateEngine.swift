import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the tiered isolation template calculation.
    protocol TieredIsolationTemplateModifier {
        func describe() -> String
        func adjust(_ item: TieredIsolationTemplate, value: Double) -> Double
    }

    final class TieredIsolationTemplateThresholdOffsetAdjuster: TieredIsolationTemplateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: TieredIsolationTemplate, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class RoundingTieredIsolationTemplateAdjuster: TieredIsolationTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredIsolationTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumTieredIsolationTemplateAdjuster: TieredIsolationTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredIsolationTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapTieredIsolationTemplateAdjuster: TieredIsolationTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredIsolationTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered isolation template steps in order and keeps a trace of each.
    final class TieredIsolationTemplateEngine {
        var steps: [any TieredIsolationTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredIsolationTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredIsolationTemplate) -> Double {
            var current = item.weightedValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [TieredIsolationTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredIsolationTemplateEngine() -> TieredIsolationTemplateEngine {
        return TieredIsolationTemplateEngine(
            steps: [
                TieredIsolationTemplateThresholdOffsetAdjuster(weight: 0.87),
                RoundingTieredIsolationTemplateAdjuster(step: 0.05),
                MinimumTieredIsolationTemplateAdjuster(minimum: 20.0),
                CapTieredIsolationTemplateAdjuster(cap: 27432.0),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 74098.0
        )
    }
}
