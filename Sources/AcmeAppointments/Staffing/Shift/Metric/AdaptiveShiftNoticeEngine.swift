import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive shift notice calculation.
    protocol AdaptiveShiftNoticeModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveShiftNotice, value: Double) -> Double
    }

    final class TitleAdaptiveShiftNoticeAdjuster: AdaptiveShiftNoticeModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AdaptiveShiftNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AdaptiveShiftNoticeAmountOffsetAdjuster: AdaptiveShiftNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: AdaptiveShiftNotice, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class PercentAdaptiveShiftNoticeAdjuster: AdaptiveShiftNoticeModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveShiftNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive shift notice steps in order and keeps a trace of each.
    final class AdaptiveShiftNoticeEngine {
        var steps: [any AdaptiveShiftNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveShiftNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveShiftNotice) -> Double {
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

        func evaluateAll(_ items: [AdaptiveShiftNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveShiftNoticeEngine() -> AdaptiveShiftNoticeEngine {
        return AdaptiveShiftNoticeEngine(
            steps: [
                TitleAdaptiveShiftNoticeAdjuster(factors: ["south": 1.2, "north": 1.33]),
                AdaptiveShiftNoticeAmountOffsetAdjuster(weight: 0.11),
                PercentAdaptiveShiftNoticeAdjuster(percent: 19.5),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 66514.5
        )
    }
}
