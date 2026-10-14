import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending claim draft calculation.
    protocol PendingClaimDraftFactor {
        func describe() -> String
        func adjust(_ item: PendingClaimDraft, value: Double) -> Double
    }

    final class MinimumPendingClaimDraftAdjuster: PendingClaimDraftFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingClaimDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPendingClaimDraftAdjuster: PendingClaimDraftFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingClaimDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelPendingClaimDraftAdjuster: PendingClaimDraftFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingClaimDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPendingClaimDraftAdjuster: PendingClaimDraftFactor {
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

        func adjust(_ item: PendingClaimDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPendingClaimDraftAdjuster: PendingClaimDraftFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingClaimDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the pending claim draft steps in order and keeps a trace of each.
    final class PendingClaimDraftEngine {
        var steps: [any PendingClaimDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingClaimDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingClaimDraft) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingClaimDraftFactor = steps[index]
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

        func evaluateAll(_ items: [PendingClaimDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingClaimDraftEngine(_ flags: Kit.Flags.Registry) -> PendingClaimDraftEngine {
        return PendingClaimDraftEngine(
            steps: [
                MinimumPendingClaimDraftAdjuster(minimum: 38.3),
                PercentPendingClaimDraftAdjuster(percent: 15.5),
                LabelPendingClaimDraftAdjuster(factors: ["south": 0.72, "east": 1.2]),
                FlaggedPendingClaimDraftAdjuster(flags: flags, flag: "pending-claim-draft-rolling", percent: -4.8),
                CapPendingClaimDraftAdjuster(cap: 12768.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 52888.8
        )
    }
}
