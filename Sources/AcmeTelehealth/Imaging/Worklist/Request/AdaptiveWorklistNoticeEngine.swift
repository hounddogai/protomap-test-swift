import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive worklist notice calculation.
    protocol AdaptiveWorklistNoticeModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveWorklistNotice, value: Double) -> Double
    }

    final class AdaptiveWorklistNoticePriorityOffsetAdjuster: AdaptiveWorklistNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: AdaptiveWorklistNotice, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class TieredAdaptiveWorklistNoticeAdjuster: AdaptiveWorklistNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveWorklistNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingAdaptiveWorklistNoticeAdjuster: AdaptiveWorklistNoticeModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveWorklistNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive worklist notice steps in order and keeps a trace of each.
    final class AdaptiveWorklistNoticeEngine {
        var steps: [any AdaptiveWorklistNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveWorklistNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveWorklistNotice) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveWorklistNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [AdaptiveWorklistNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveWorklistNoticeEngine() -> AdaptiveWorklistNoticeEngine {
        return AdaptiveWorklistNoticeEngine(
            steps: [
                AdaptiveWorklistNoticePriorityOffsetAdjuster(weight: 0.04),
                TieredAdaptiveWorklistNoticeAdjuster(
                    bounds: [297.0, 4112.0, 8032.0, 8602.0],
                    rates: [0.82, 0.91, 0.82, 0.86]
                ),
                RoundingAdaptiveWorklistNoticeAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 34777.8
        )
    }
}
