import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol baseline calculation.
    protocol CareProtocolBaselineModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolBaseline, value: Double) -> Double
    }

    final class RoundingCareProtocolBaselineAdjuster: CareProtocolBaselineModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCareProtocolBaselineAdjuster: CareProtocolBaselineModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CareProtocolBaselineMinimumOffsetAdjuster: CareProtocolBaselineModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: CareProtocolBaseline, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    /// Runs the care protocol baseline steps in order and keeps a trace of each.
    final class CareProtocolBaselineEngine {
        var steps: [any CareProtocolBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareProtocolBaseline) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolBaselineModifier = steps[index]
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

        func evaluateAll(_ items: [CareProtocolBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareProtocolBaselineEngine() -> CareProtocolBaselineEngine {
        return CareProtocolBaselineEngine(
            steps: [
                RoundingCareProtocolBaselineAdjuster(step: 1.0),
                PercentCareProtocolBaselineAdjuster(percent: -1.9),
                CareProtocolBaselineMinimumOffsetAdjuster(weight: 1.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 25033.3
        )
    }
}
