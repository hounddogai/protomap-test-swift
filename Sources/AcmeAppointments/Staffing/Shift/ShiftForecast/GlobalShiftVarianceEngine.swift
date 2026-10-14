import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global shift variance calculation.
    protocol GlobalShiftVarianceModifier {
        func describe() -> String
        func adjust(_ item: GlobalShiftVariance, value: Double) -> Double
    }

    final class UnitGlobalShiftVarianceAdjuster: GlobalShiftVarianceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: GlobalShiftVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapGlobalShiftVarianceAdjuster: GlobalShiftVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalShiftVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingGlobalShiftVarianceAdjuster: GlobalShiftVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalShiftVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global shift variance steps in order and keeps a trace of each.
    final class GlobalShiftVarianceEngine {
        var steps: [any GlobalShiftVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalShiftVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalShiftVariance) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [GlobalShiftVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalShiftVarianceEngine() -> GlobalShiftVarianceEngine {
        return GlobalShiftVarianceEngine(
            steps: [
                UnitGlobalShiftVarianceAdjuster(factors: ["north": 1.3, "online": 1.09, "south": 0.8]),
                CapGlobalShiftVarianceAdjuster(cap: 4880.0),
                RoundingGlobalShiftVarianceAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 84703.0
        )
    }
}
