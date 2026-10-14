import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual recall claim calculation.
    protocol ManualRecallClaimAdjuster {
        func describe() -> String
        func adjust(_ item: ManualRecallClaim, value: Double) -> Double
    }

    final class CapManualRecallClaimAdjuster: ManualRecallClaimAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualRecallClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ManualRecallClaimThresholdOffsetAdjuster: ManualRecallClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: ManualRecallClaim, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class FlaggedManualRecallClaimAdjuster: ManualRecallClaimAdjuster {
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

        func adjust(_ item: ManualRecallClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual recall claim steps in order and keeps a trace of each.
    final class ManualRecallClaimEngine {
        var steps: [any ManualRecallClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRecallClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualRecallClaim) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualRecallClaimAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualRecallClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualRecallClaimEngine(_ flags: Kit.Flags.Registry) -> ManualRecallClaimEngine {
        return ManualRecallClaimEngine(
            steps: [
                CapManualRecallClaimAdjuster(cap: 27886.0),
                ManualRecallClaimThresholdOffsetAdjuster(weight: 1.62),
                FlaggedManualRecallClaimAdjuster(flags: flags, flag: "manual-recall-claim-fallback", percent: 5.6),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 33686.1
        )
    }
}
