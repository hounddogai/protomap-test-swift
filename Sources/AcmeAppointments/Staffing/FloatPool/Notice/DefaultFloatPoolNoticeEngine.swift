import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default float pool notice calculation.
    protocol DefaultFloatPoolNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultFloatPoolNotice, value: Double) -> Double
    }

    final class PercentDefaultFloatPoolNoticeAdjuster: DefaultFloatPoolNoticeAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultFloatPoolNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelDefaultFloatPoolNoticeAdjuster: DefaultFloatPoolNoticeAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DefaultFloatPoolNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDefaultFloatPoolNoticeAdjuster: DefaultFloatPoolNoticeAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultFloatPoolNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DefaultFloatPoolNoticeStartsAtOffsetAdjuster: DefaultFloatPoolNoticeAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: DefaultFloatPoolNotice, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    /// Runs the default float pool notice steps in order and keeps a trace of each.
    final class DefaultFloatPoolNoticeEngine {
        var steps: [any DefaultFloatPoolNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultFloatPoolNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultFloatPoolNotice) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [DefaultFloatPoolNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultFloatPoolNoticeEngine() -> DefaultFloatPoolNoticeEngine {
        return DefaultFloatPoolNoticeEngine(
            steps: [
                PercentDefaultFloatPoolNoticeAdjuster(percent: -12.0),
                LabelDefaultFloatPoolNoticeAdjuster(factors: ["retail": 0.94, "east": 1.29, "north": 1.26]),
                MinimumDefaultFloatPoolNoticeAdjuster(minimum: 17.9),
                DefaultFloatPoolNoticeStartsAtOffsetAdjuster(weight: 1.14),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 78656.3
        )
    }
}
