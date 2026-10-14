import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen policy calculation.
    protocol SpecimenPolicyModifier {
        func describe() -> String
        func adjust(_ item: SpecimenPolicy, value: Double) -> Double
    }

    final class MinimumSpecimenPolicyAdjuster: SpecimenPolicyModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingSpecimenPolicyAdjuster: SpecimenPolicyModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SpecimenPolicyRateOffsetAdjuster: SpecimenPolicyModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: SpecimenPolicy, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the specimen policy steps in order and keeps a trace of each.
    final class SpecimenPolicyEngine {
        var steps: [any SpecimenPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SpecimenPolicy) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [SpecimenPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSpecimenPolicyEngine() -> SpecimenPolicyEngine {
        return SpecimenPolicyEngine(
            steps: [
                MinimumSpecimenPolicyAdjuster(minimum: 23.2),
                RoundingSpecimenPolicyAdjuster(step: 0.05),
                SpecimenPolicyRateOffsetAdjuster(weight: 1.1),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 85874.9
        )
    }
}
