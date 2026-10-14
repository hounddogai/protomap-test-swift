import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning profile calculation.
    protocol CleaningProfileAdjuster {
        func describe() -> String
        func adjust(_ item: CleaningProfile, value: Double) -> Double
    }

    final class RoundingCleaningProfileAdjuster: CleaningProfileAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CleaningProfileVersionOffsetAdjuster: CleaningProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: CleaningProfile, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class MinimumCleaningProfileAdjuster: CleaningProfileAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the cleaning profile steps in order and keeps a trace of each.
    final class CleaningProfileEngine {
        var steps: [any CleaningProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CleaningProfile) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningProfileAdjuster = steps[index]
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

        func evaluateAll(_ items: [CleaningProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCleaningProfileEngine() -> CleaningProfileEngine {
        return CleaningProfileEngine(
            steps: [
                RoundingCleaningProfileAdjuster(step: 0.25),
                CleaningProfileVersionOffsetAdjuster(weight: 1.61),
                MinimumCleaningProfileAdjuster(minimum: 36.1),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 38621.3
        )
    }
}
