import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default care gap assignment calculation.
    protocol DefaultCareGapAssignmentModifier {
        func describe() -> String
        func adjust(_ item: DefaultCareGapAssignment, value: Double) -> Double
    }

    final class CapDefaultCareGapAssignmentAdjuster: DefaultCareGapAssignmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultCareGapAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryDefaultCareGapAssignmentAdjuster: DefaultCareGapAssignmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: DefaultCareGapAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDefaultCareGapAssignmentAdjuster: DefaultCareGapAssignmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCareGapAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultCareGapAssignmentAdjuster: DefaultCareGapAssignmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultCareGapAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumDefaultCareGapAssignmentAdjuster: DefaultCareGapAssignmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultCareGapAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the default care gap assignment steps in order and keeps a trace of each.
    final class DefaultCareGapAssignmentEngine {
        var steps: [any DefaultCareGapAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCareGapAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultCareGapAssignment) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [DefaultCareGapAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultCareGapAssignmentEngine() -> DefaultCareGapAssignmentEngine {
        return DefaultCareGapAssignmentEngine(
            steps: [
                CapDefaultCareGapAssignmentAdjuster(cap: 16192.0),
                CountryDefaultCareGapAssignmentAdjuster(factors: ["central": 1.08, "west": 1.0]),
                PercentDefaultCareGapAssignmentAdjuster(percent: -19.4),
                RoundingDefaultCareGapAssignmentAdjuster(step: 1.0),
                MinimumDefaultCareGapAssignmentAdjuster(minimum: 19.8),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 79518.5
        )
    }
}
