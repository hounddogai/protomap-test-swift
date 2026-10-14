import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction window calculation.
    protocol InteractionWindowStep {
        func describe() -> String
        func adjust(_ item: InteractionWindow, value: Double) -> Double
    }

    final class MinimumInteractionWindowAdjuster: InteractionWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedInteractionWindowAdjuster: InteractionWindowStep {
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

        func adjust(_ item: InteractionWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapInteractionWindowAdjuster: InteractionWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredInteractionWindowAdjuster: InteractionWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingInteractionWindowAdjuster: InteractionWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class InteractionWindowThresholdOffsetAdjuster: InteractionWindowStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: InteractionWindow, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    /// Runs the interaction window steps in order and keeps a trace of each.
    final class InteractionWindowEngine {
        var steps: [any InteractionWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: InteractionWindow) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [InteractionWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultInteractionWindowEngine(_ flags: Kit.Flags.Registry) -> InteractionWindowEngine {
        return InteractionWindowEngine(
            steps: [
                MinimumInteractionWindowAdjuster(minimum: 6.7),
                FlaggedInteractionWindowAdjuster(flags: flags, flag: "interaction-window-default", percent: -7.3),
                CapInteractionWindowAdjuster(cap: 12090.0),
                TieredInteractionWindowAdjuster(
                    bounds: [3668.0, 4984.0, 6077.0, 8805.0],
                    rates: [0.85, 1.02, 0.85, 0.88]
                ),
                RoundingInteractionWindowAdjuster(step: 5.0),
                InteractionWindowThresholdOffsetAdjuster(weight: 1.77),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 81221.3
        )
    }
}
