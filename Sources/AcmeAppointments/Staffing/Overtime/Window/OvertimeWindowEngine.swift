import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime window calculation.
    protocol OvertimeWindowAdjuster {
        func describe() -> String
        func adjust(_ item: OvertimeWindow, value: Double) -> Double
    }

    final class TitleOvertimeWindowAdjuster: OvertimeWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: OvertimeWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapOvertimeWindowAdjuster: OvertimeWindowAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OvertimeWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredOvertimeWindowAdjuster: OvertimeWindowAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentOvertimeWindowAdjuster: OvertimeWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingOvertimeWindowAdjuster: OvertimeWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the overtime window steps in order and keeps a trace of each.
    final class OvertimeWindowEngine {
        var steps: [any OvertimeWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OvertimeWindow) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimeWindowAdjuster = steps[index]
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

        func evaluateAll(_ items: [OvertimeWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOvertimeWindowEngine() -> OvertimeWindowEngine {
        return OvertimeWindowEngine(
            steps: [
                TitleOvertimeWindowAdjuster(factors: ["south": 1.08, "east": 0.9]),
                CapOvertimeWindowAdjuster(cap: 25153.0),
                TieredOvertimeWindowAdjuster(bounds: [2187.0, 8730.0, 9785.0], rates: [1.07, 1.07, 0.99]),
                PercentOvertimeWindowAdjuster(percent: 16.8),
                RoundingOvertimeWindowAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 10261.6
        )
    }
}
