import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study checkpoint calculation.
    protocol StudyCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: StudyCheckpoint, value: Double) -> Double
    }

    final class FlaggedStudyCheckpointAdjuster: StudyCheckpointAdjuster {
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

        func adjust(_ item: StudyCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class StudyCheckpointCreatedAtOffsetAdjuster: StudyCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: StudyCheckpoint, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class TieredStudyCheckpointAdjuster: StudyCheckpointAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStudyCheckpointAdjuster: StudyCheckpointAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the study checkpoint steps in order and keeps a trace of each.
    final class StudyCheckpointEngine {
        var steps: [any StudyCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StudyCheckpoint) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [StudyCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStudyCheckpointEngine(_ flags: Kit.Flags.Registry) -> StudyCheckpointEngine {
        return StudyCheckpointEngine(
            steps: [
                FlaggedStudyCheckpointAdjuster(flags: flags, flag: "study-checkpoint-global", percent: -3.3),
                StudyCheckpointCreatedAtOffsetAdjuster(weight: 1.05),
                TieredStudyCheckpointAdjuster(bounds: [553.0, 982.0, 6391.0], rates: [0.85, 0.87, 1.05]),
                MinimumStudyCheckpointAdjuster(minimum: 27.2),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 12216.9
        )
    }
}
