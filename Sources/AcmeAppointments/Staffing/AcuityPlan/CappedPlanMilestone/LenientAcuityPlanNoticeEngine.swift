import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the lenient acuity plan notice calculation.
    protocol LenientAcuityPlanNoticeModifier {
        func describe() -> String
        func adjust(_ item: LenientAcuityPlanNotice, value: Double) -> Double
    }

    final class CapLenientAcuityPlanNoticeAdjuster: LenientAcuityPlanNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientAcuityPlanNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleLenientAcuityPlanNoticeAdjuster: LenientAcuityPlanNoticeModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientAcuityPlanNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLenientAcuityPlanNoticeAdjuster: LenientAcuityPlanNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientAcuityPlanNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLenientAcuityPlanNoticeAdjuster: LenientAcuityPlanNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientAcuityPlanNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LenientAcuityPlanNoticeLimitOffsetAdjuster: LenientAcuityPlanNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: LenientAcuityPlanNotice, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class RoundingLenientAcuityPlanNoticeAdjuster: LenientAcuityPlanNoticeModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientAcuityPlanNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient acuity plan notice steps in order and keeps a trace of each.
    final class LenientAcuityPlanNoticeEngine {
        var steps: [any LenientAcuityPlanNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientAcuityPlanNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientAcuityPlanNotice) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientAcuityPlanNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [LenientAcuityPlanNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientAcuityPlanNoticeEngine() -> LenientAcuityPlanNoticeEngine {
        return LenientAcuityPlanNoticeEngine(
            steps: [
                CapLenientAcuityPlanNoticeAdjuster(cap: 40784.0),
                TitleLenientAcuityPlanNoticeAdjuster(factors: ["east": 0.83]),
                MinimumLenientAcuityPlanNoticeAdjuster(minimum: 7.9),
                TieredLenientAcuityPlanNoticeAdjuster(
                    bounds: [1028.0, 7773.0, 8955.0, 9233.0],
                    rates: [1.08, 0.9, 0.8, 0.93]
                ),
                LenientAcuityPlanNoticeLimitOffsetAdjuster(weight: 0.19),
                RoundingLenientAcuityPlanNoticeAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 7294.7
        )
    }
}
