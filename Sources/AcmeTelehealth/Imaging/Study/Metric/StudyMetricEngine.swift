import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study metric calculation.
    protocol StudyMetricStep {
        func describe() -> String
        func adjust(_ item: StudyMetric, value: Double) -> Double
    }

    final class MinimumStudyMetricAdjuster: StudyMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStudyMetricAdjuster: StudyMetricStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedStudyMetricAdjuster: StudyMetricStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: StudyMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the study metric steps in order and keeps a trace of each.
    final class StudyMetricEngine {
        var steps: [any StudyMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StudyMetric) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [StudyMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStudyMetricEngine(_ flags: Kit.Flags.Registry) -> StudyMetricEngine {
        return StudyMetricEngine(
            steps: [
                MinimumStudyMetricAdjuster(minimum: 1.9),
                CapStudyMetricAdjuster(cap: 7819.0),
                FlaggedStudyMetricAdjuster(flags: flags, flag: "study-metric-pending", percent: 6.9),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 11663.7
        )
    }
}
