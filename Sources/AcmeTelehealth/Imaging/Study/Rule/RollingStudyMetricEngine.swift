import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling study metric calculation.
    protocol RollingStudyMetricAdjuster {
        func describe() -> String
        func adjust(_ item: RollingStudyMetric, value: Double) -> Double
    }

    final class CapRollingStudyMetricAdjuster: RollingStudyMetricAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingStudyMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRollingStudyMetricAdjuster: RollingStudyMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingStudyMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitRollingStudyMetricAdjuster: RollingStudyMetricAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: RollingStudyMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RollingStudyMetricStartsAtOffsetAdjuster: RollingStudyMetricAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: RollingStudyMetric, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    /// Runs the rolling study metric steps in order and keeps a trace of each.
    final class RollingStudyMetricEngine {
        var steps: [any RollingStudyMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingStudyMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingStudyMetric) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [RollingStudyMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingStudyMetricEngine() -> RollingStudyMetricEngine {
        return RollingStudyMetricEngine(
            steps: [
                CapRollingStudyMetricAdjuster(cap: 14257.0),
                MinimumRollingStudyMetricAdjuster(minimum: 20.6),
                UnitRollingStudyMetricAdjuster(factors: ["west": 1.12]),
                RollingStudyMetricStartsAtOffsetAdjuster(weight: 1.81),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 35835.5
        )
    }
}
