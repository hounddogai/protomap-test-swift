import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual isolation segment calculation.
    protocol ManualIsolationSegmentModifier {
        func describe() -> String
        func adjust(_ item: ManualIsolationSegment, value: Double) -> Double
    }

    final class CategoryManualIsolationSegmentAdjuster: ManualIsolationSegmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: ManualIsolationSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingManualIsolationSegmentAdjuster: ManualIsolationSegmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualIsolationSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapManualIsolationSegmentAdjuster: ManualIsolationSegmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualIsolationSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentManualIsolationSegmentAdjuster: ManualIsolationSegmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualIsolationSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualIsolationSegmentAdjuster: ManualIsolationSegmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualIsolationSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ManualIsolationSegmentScoreOffsetAdjuster: ManualIsolationSegmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ManualIsolationSegment, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    /// Runs the manual isolation segment steps in order and keeps a trace of each.
    final class ManualIsolationSegmentEngine {
        var steps: [any ManualIsolationSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualIsolationSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualIsolationSegment) -> Double {
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

        func evaluateAll(_ items: [ManualIsolationSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualIsolationSegmentEngine() -> ManualIsolationSegmentEngine {
        return ManualIsolationSegmentEngine(
            steps: [
                CategoryManualIsolationSegmentAdjuster(factors: ["retail": 0.76, "west": 0.88, "south": 1.27]),
                RoundingManualIsolationSegmentAdjuster(step: 0.05),
                CapManualIsolationSegmentAdjuster(cap: 11233.0),
                PercentManualIsolationSegmentAdjuster(percent: -12.6),
                MinimumManualIsolationSegmentAdjuster(minimum: 18.1),
                ManualIsolationSegmentScoreOffsetAdjuster(weight: 0.46),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 92971.2
        )
    }
}
