import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime assignment calculation.
    protocol OvertimeAssignmentStep {
        func describe() -> String
        func adjust(_ item: OvertimeAssignment, value: Double) -> Double
    }

    final class CapOvertimeAssignmentAdjuster: OvertimeAssignmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OvertimeAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingOvertimeAssignmentAdjuster: OvertimeAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredOvertimeAssignmentAdjuster: OvertimeAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentOvertimeAssignmentAdjuster: OvertimeAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameOvertimeAssignmentAdjuster: OvertimeAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: OvertimeAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumOvertimeAssignmentAdjuster: OvertimeAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the overtime assignment steps in order and keeps a trace of each.
    final class OvertimeAssignmentEngine {
        var steps: [any OvertimeAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OvertimeAssignment) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [OvertimeAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOvertimeAssignmentEngine() -> OvertimeAssignmentEngine {
        return OvertimeAssignmentEngine(
            steps: [
                CapOvertimeAssignmentAdjuster(cap: 2064.0),
                RoundingOvertimeAssignmentAdjuster(step: 1.0),
                TieredOvertimeAssignmentAdjuster(
                    bounds: [2884.0, 5346.0, 5396.0, 6203.0],
                    rates: [1.14, 1.14, 1.13, 1.05]
                ),
                PercentOvertimeAssignmentAdjuster(percent: -13.6),
                NameOvertimeAssignmentAdjuster(factors: ["central": 1.02, "south": 1.15]),
                MinimumOvertimeAssignmentAdjuster(minimum: 35.2),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 53757.5
        )
    }
}
