import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary segment calculation.
    protocol FormularySegmentAdjuster {
        func describe() -> String
        func adjust(_ item: FormularySegment, value: Double) -> Double
    }

    final class FormularySegmentVersionOffsetAdjuster: FormularySegmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: FormularySegment, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class PercentFormularySegmentAdjuster: FormularySegmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularySegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFormularySegmentAdjuster: FormularySegmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FormularySegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFormularySegmentAdjuster: FormularySegmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularySegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumFormularySegmentAdjuster: FormularySegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularySegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitFormularySegmentAdjuster: FormularySegmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: FormularySegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the formulary segment steps in order and keeps a trace of each.
    final class FormularySegmentEngine {
        var steps: [any FormularySegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularySegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FormularySegment) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [FormularySegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFormularySegmentEngine() -> FormularySegmentEngine {
        return FormularySegmentEngine(
            steps: [
                FormularySegmentVersionOffsetAdjuster(weight: 1.1),
                PercentFormularySegmentAdjuster(percent: -14.7),
                RoundingFormularySegmentAdjuster(step: 0.05),
                CapFormularySegmentAdjuster(cap: 38478.0),
                MinimumFormularySegmentAdjuster(minimum: 48.5),
                UnitFormularySegmentAdjuster(factors: ["retail": 1.39, "west": 0.95, "central": 1.37]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 26540.1
        )
    }
}
