import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime draft calculation.
    protocol OvertimeDraftAdjuster {
        func describe() -> String
        func adjust(_ item: OvertimeDraft, value: Double) -> Double
    }

    final class PercentOvertimeDraftAdjuster: OvertimeDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingOvertimeDraftAdjuster: OvertimeDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class OvertimeDraftCostOffsetAdjuster: OvertimeDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: OvertimeDraft, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class MinimumOvertimeDraftAdjuster: OvertimeDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the overtime draft steps in order and keeps a trace of each.
    final class OvertimeDraftEngine {
        var steps: [any OvertimeDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OvertimeDraft) -> Double {
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

        func evaluateAll(_ items: [OvertimeDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOvertimeDraftEngine() -> OvertimeDraftEngine {
        return OvertimeDraftEngine(
            steps: [
                PercentOvertimeDraftAdjuster(percent: 0.9),
                RoundingOvertimeDraftAdjuster(step: 0.05),
                OvertimeDraftCostOffsetAdjuster(weight: 1.42),
                MinimumOvertimeDraftAdjuster(minimum: 34.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 17742.9
        )
    }
}
