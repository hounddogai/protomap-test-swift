import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending reference range override calculation.
    protocol PendingReferenceRangeOverrideFactor {
        func describe() -> String
        func adjust(_ item: PendingReferenceRangeOverride, value: Double) -> Double
    }

    final class MinimumPendingReferenceRangeOverrideAdjuster: PendingReferenceRangeOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingReferenceRangeOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPendingReferenceRangeOverrideAdjuster: PendingReferenceRangeOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingReferenceRangeOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelPendingReferenceRangeOverrideAdjuster: PendingReferenceRangeOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingReferenceRangeOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending reference range override steps in order and keeps a trace of each.
    final class PendingReferenceRangeOverrideEngine {
        var steps: [any PendingReferenceRangeOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingReferenceRangeOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingReferenceRangeOverride) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [PendingReferenceRangeOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingReferenceRangeOverrideEngine() -> PendingReferenceRangeOverrideEngine {
        return PendingReferenceRangeOverrideEngine(
            steps: [
                MinimumPendingReferenceRangeOverrideAdjuster(minimum: 34.6),
                PercentPendingReferenceRangeOverrideAdjuster(percent: 24.3),
                LabelPendingReferenceRangeOverrideAdjuster(factors: ["central": 1.08, "retail": 1.08]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 85652.5
        )
    }
}
