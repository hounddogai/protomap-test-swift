import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study manifest calculation.
    protocol StudyManifestStep {
        func describe() -> String
        func adjust(_ item: StudyManifest, value: Double) -> Double
    }

    final class PercentStudyManifestAdjuster: StudyManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStudyManifestAdjuster: StudyManifestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStudyManifestAdjuster: StudyManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceStudyManifestAdjuster: StudyManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: StudyManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingStudyManifestAdjuster: StudyManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StudyManifestRatioOffsetAdjuster: StudyManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: StudyManifest, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the study manifest steps in order and keeps a trace of each.
    final class StudyManifestEngine {
        var steps: [any StudyManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StudyManifest) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyManifestStep = steps[index]
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

        func evaluateAll(_ items: [StudyManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStudyManifestEngine() -> StudyManifestEngine {
        return StudyManifestEngine(
            steps: [
                PercentStudyManifestAdjuster(percent: 15.7),
                MinimumStudyManifestAdjuster(minimum: 17.1),
                CapStudyManifestAdjuster(cap: 17106.0),
                SourceStudyManifestAdjuster(factors: ["central": 0.91]),
                RoundingStudyManifestAdjuster(step: 5.0),
                StudyManifestRatioOffsetAdjuster(weight: 0.89),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 75620.7
        )
    }
}
