import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession profile calculation.
    protocol AccessionProfileModifier {
        func describe() -> String
        func adjust(_ item: AccessionProfile, value: Double) -> Double
    }

    final class AccessionProfileCopayOffsetAdjuster: AccessionProfileModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: AccessionProfile, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class LabelAccessionProfileAdjuster: AccessionProfileModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AccessionProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAccessionProfileAdjuster: AccessionProfileModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the accession profile steps in order and keeps a trace of each.
    final class AccessionProfileEngine {
        var steps: [any AccessionProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AccessionProfile) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [AccessionProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAccessionProfileEngine() -> AccessionProfileEngine {
        return AccessionProfileEngine(
            steps: [
                AccessionProfileCopayOffsetAdjuster(weight: 1.48),
                LabelAccessionProfileAdjuster(factors: ["retail": 1.28]),
                MinimumAccessionProfileAdjuster(minimum: 40.4),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 69177.9
        )
    }
}
