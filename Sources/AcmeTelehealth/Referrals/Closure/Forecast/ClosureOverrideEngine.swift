import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure override calculation.
    protocol ClosureOverrideAdjuster {
        func describe() -> String
        func adjust(_ item: ClosureOverride, value: Double) -> Double
    }

    final class ClosureOverrideMarginOffsetAdjuster: ClosureOverrideAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: ClosureOverride, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class LabelClosureOverrideAdjuster: ClosureOverrideAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ClosureOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentClosureOverrideAdjuster: ClosureOverrideAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the closure override steps in order and keeps a trace of each.
    final class ClosureOverrideEngine {
        var steps: [any ClosureOverrideAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureOverrideAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ClosureOverride) -> Double {
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

        func evaluateAll(_ items: [ClosureOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultClosureOverrideEngine() -> ClosureOverrideEngine {
        return ClosureOverrideEngine(
            steps: [
                ClosureOverrideMarginOffsetAdjuster(weight: 1.97),
                LabelClosureOverrideAdjuster(factors: ["south": 0.81]),
                PercentClosureOverrideAdjuster(percent: 20.6),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 33323.3
        )
    }
}
