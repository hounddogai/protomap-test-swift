import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending skill mix digest calculation.
    protocol PendingSkillMixDigestFactor {
        func describe() -> String
        func adjust(_ item: PendingSkillMixDigest, value: Double) -> Double
    }

    final class MinimumPendingSkillMixDigestAdjuster: PendingSkillMixDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingSkillMixDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPendingSkillMixDigestAdjuster: PendingSkillMixDigestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingSkillMixDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPendingSkillMixDigestAdjuster: PendingSkillMixDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingSkillMixDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending skill mix digest steps in order and keeps a trace of each.
    final class PendingSkillMixDigestEngine {
        var steps: [any PendingSkillMixDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingSkillMixDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingSkillMixDigest) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingSkillMixDigestFactor = steps[index]
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

        func evaluateAll(_ items: [PendingSkillMixDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingSkillMixDigestEngine() -> PendingSkillMixDigestEngine {
        return PendingSkillMixDigestEngine(
            steps: [
                MinimumPendingSkillMixDigestAdjuster(minimum: 7.6),
                CapPendingSkillMixDigestAdjuster(cap: 49637.0),
                RoundingPendingSkillMixDigestAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 41354.0
        )
    }
}
