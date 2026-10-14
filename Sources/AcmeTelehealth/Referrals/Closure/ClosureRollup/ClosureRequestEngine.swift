import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure request calculation.
    protocol ClosureRequestStep {
        func describe() -> String
        func adjust(_ item: ClosureRequest, value: Double) -> Double
    }

    final class FlaggedClosureRequestAdjuster: ClosureRequestStep {
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

        func adjust(_ item: ClosureRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumClosureRequestAdjuster: ClosureRequestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentClosureRequestAdjuster: ClosureRequestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapClosureRequestAdjuster: ClosureRequestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the closure request steps in order and keeps a trace of each.
    final class ClosureRequestEngine {
        var steps: [any ClosureRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClosureRequest) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureRequestStep = steps[index]
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

        func evaluateAll(_ items: [ClosureRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClosureRequestEngine(_ flags: Kit.Flags.Registry) -> ClosureRequestEngine {
        return ClosureRequestEngine(
            steps: [
                FlaggedClosureRequestAdjuster(flags: flags, flag: "closure-request-adaptive", percent: -8.9),
                MinimumClosureRequestAdjuster(minimum: 1.8),
                PercentClosureRequestAdjuster(percent: 12.6),
                CapClosureRequestAdjuster(cap: 4107.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 89675.4
        )
    }
}
