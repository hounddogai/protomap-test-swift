import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result digest calculation.
    protocol ResultDigestStep {
        func describe() -> String
        func adjust(_ item: ResultDigest, value: Double) -> Double
    }

    final class ResultDigestBudgetOffsetAdjuster: ResultDigestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: ResultDigest, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class FlaggedResultDigestAdjuster: ResultDigestStep {
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

        func adjust(_ item: ResultDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapResultDigestAdjuster: ResultDigestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ResultDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameResultDigestAdjuster: ResultDigestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ResultDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the result digest steps in order and keeps a trace of each.
    final class ResultDigestEngine {
        var steps: [any ResultDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ResultDigest) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ResultDigestStep = steps[index]
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

        func evaluateAll(_ items: [ResultDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultResultDigestEngine(_ flags: Kit.Flags.Registry) -> ResultDigestEngine {
        return ResultDigestEngine(
            steps: [
                ResultDigestBudgetOffsetAdjuster(weight: 1.98),
                FlaggedResultDigestAdjuster(flags: flags, flag: "result-digest-adaptive", percent: 9.7),
                CapResultDigestAdjuster(cap: 33773.0),
                NameResultDigestAdjuster(factors: ["central": 1.34, "retail": 1.02, "north": 1.36]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 50940.3
        )
    }
}
