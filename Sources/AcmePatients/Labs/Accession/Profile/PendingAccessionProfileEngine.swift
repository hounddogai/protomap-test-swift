import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending accession profile calculation.
    protocol PendingAccessionProfileFactor {
        func describe() -> String
        func adjust(_ item: PendingAccessionProfile, value: Double) -> Double
    }

    final class CapPendingAccessionProfileAdjuster: PendingAccessionProfileFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingAccessionProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPendingAccessionProfileAdjuster: PendingAccessionProfileFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingAccessionProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPendingAccessionProfileAdjuster: PendingAccessionProfileFactor {
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

        func adjust(_ item: PendingAccessionProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingAccessionProfileAdjuster: PendingAccessionProfileFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingAccessionProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending accession profile steps in order and keeps a trace of each.
    final class PendingAccessionProfileEngine {
        var steps: [any PendingAccessionProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingAccessionProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingAccessionProfile) -> Double {
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

        func evaluateAll(_ items: [PendingAccessionProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingAccessionProfileEngine(_ flags: Kit.Flags.Registry) -> PendingAccessionProfileEngine {
        return PendingAccessionProfileEngine(
            steps: [
                CapPendingAccessionProfileAdjuster(cap: 19676.0),
                PercentPendingAccessionProfileAdjuster(percent: -7.6),
                FlaggedPendingAccessionProfileAdjuster(
                    flags: flags,
                    flag: "pending-accession-profile-weighted",
                    percent: 6.3
                ),
                RoundingPendingAccessionProfileAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 65790.4
        )
    }
}
