import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier variance calculation.
    protocol CourierVarianceFactor {
        func describe() -> String
        func adjust(_ item: CourierVariance, value: Double) -> Double
    }

    final class CourierVarianceVisitMinutesOffsetAdjuster: CourierVarianceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: CourierVariance, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class RoundingCourierVarianceAdjuster: CourierVarianceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCourierVarianceAdjuster: CourierVarianceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCourierVarianceAdjuster: CourierVarianceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCourierVarianceAdjuster: CourierVarianceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the courier variance steps in order and keeps a trace of each.
    final class CourierVarianceEngine {
        var steps: [any CourierVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CourierVariance) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CourierVarianceFactor = steps[index]
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

        func evaluateAll(_ items: [CourierVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCourierVarianceEngine() -> CourierVarianceEngine {
        return CourierVarianceEngine(
            steps: [
                CourierVarianceVisitMinutesOffsetAdjuster(weight: 1.55),
                RoundingCourierVarianceAdjuster(step: 0.5),
                PercentCourierVarianceAdjuster(percent: 13.1),
                CapCourierVarianceAdjuster(cap: 28285.0),
                MinimumCourierVarianceAdjuster(minimum: 23.1),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 7775.9
        )
    }
}
