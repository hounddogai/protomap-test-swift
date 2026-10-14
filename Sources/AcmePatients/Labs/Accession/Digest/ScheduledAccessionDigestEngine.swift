import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled accession digest calculation.
    protocol ScheduledAccessionDigestFactor {
        func describe() -> String
        func adjust(_ item: ScheduledAccessionDigest, value: Double) -> Double
    }

    final class MinimumScheduledAccessionDigestAdjuster: ScheduledAccessionDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledAccessionDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledAccessionDigestAdjuster: ScheduledAccessionDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledAccessionDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitScheduledAccessionDigestAdjuster: ScheduledAccessionDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ScheduledAccessionDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the scheduled accession digest steps in order and keeps a trace of each.
    final class ScheduledAccessionDigestEngine {
        var steps: [any ScheduledAccessionDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAccessionDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledAccessionDigest) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledAccessionDigestFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledAccessionDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledAccessionDigestEngine() -> ScheduledAccessionDigestEngine {
        return ScheduledAccessionDigestEngine(
            steps: [
                MinimumScheduledAccessionDigestAdjuster(minimum: 45.2),
                RoundingScheduledAccessionDigestAdjuster(step: 5.0),
                UnitScheduledAccessionDigestAdjuster(factors: ["online": 0.96, "retail": 0.84]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 69122.2
        )
    }
}
