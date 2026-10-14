import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled program profile calculation.
    protocol ScheduledProgramProfileAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledProgramProfile, value: Double) -> Double
    }

    final class TitleScheduledProgramProfileAdjuster: ScheduledProgramProfileAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ScheduledProgramProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapScheduledProgramProfileAdjuster: ScheduledProgramProfileAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledProgramProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumScheduledProgramProfileAdjuster: ScheduledProgramProfileAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledProgramProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ScheduledProgramProfileLimitOffsetAdjuster: ScheduledProgramProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: ScheduledProgramProfile, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the scheduled program profile steps in order and keeps a trace of each.
    final class ScheduledProgramProfileEngine {
        var steps: [any ScheduledProgramProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledProgramProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledProgramProfile) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [ScheduledProgramProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledProgramProfileEngine() -> ScheduledProgramProfileEngine {
        return ScheduledProgramProfileEngine(
            steps: [
                TitleScheduledProgramProfileAdjuster(factors: ["west": 1.34]),
                CapScheduledProgramProfileAdjuster(cap: 771.0),
                MinimumScheduledProgramProfileAdjuster(minimum: 14.2),
                ScheduledProgramProfileLimitOffsetAdjuster(weight: 0.11),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 17687.3
        )
    }
}
