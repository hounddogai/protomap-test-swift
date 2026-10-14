import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task digest calculation.
    protocol TaskDigestAdjuster {
        func describe() -> String
        func adjust(_ item: TaskDigest, value: Double) -> Double
    }

    final class RoundingTaskDigestAdjuster: TaskDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TaskDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentTaskDigestAdjuster: TaskDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleTaskDigestAdjuster: TaskDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: TaskDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTaskDigestAdjuster: TaskDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the task digest steps in order and keeps a trace of each.
    final class TaskDigestEngine {
        var steps: [any TaskDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TaskDigest) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [TaskDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTaskDigestEngine() -> TaskDigestEngine {
        return TaskDigestEngine(
            steps: [
                RoundingTaskDigestAdjuster(step: 1.0),
                PercentTaskDigestAdjuster(percent: -9.3),
                TitleTaskDigestAdjuster(factors: ["online": 0.77, "south": 1.28]),
                CapTaskDigestAdjuster(cap: 37474.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 34893.5
        )
    }
}
