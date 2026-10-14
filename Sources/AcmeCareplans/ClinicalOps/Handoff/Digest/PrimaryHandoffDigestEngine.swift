import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary handoff digest calculation.
    protocol PrimaryHandoffDigestFactor {
        func describe() -> String
        func adjust(_ item: PrimaryHandoffDigest, value: Double) -> Double
    }

    final class PercentPrimaryHandoffDigestAdjuster: PrimaryHandoffDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryHandoffDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPrimaryHandoffDigestAdjuster: PrimaryHandoffDigestFactor {
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

        func adjust(_ item: PrimaryHandoffDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryHandoffDigestDosageMgOffsetAdjuster: PrimaryHandoffDigestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: PrimaryHandoffDigest, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class RoundingPrimaryHandoffDigestAdjuster: PrimaryHandoffDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryHandoffDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary handoff digest steps in order and keeps a trace of each.
    final class PrimaryHandoffDigestEngine {
        var steps: [any PrimaryHandoffDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryHandoffDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryHandoffDigest) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [PrimaryHandoffDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryHandoffDigestEngine(_ flags: Kit.Flags.Registry) -> PrimaryHandoffDigestEngine {
        return PrimaryHandoffDigestEngine(
            steps: [
                PercentPrimaryHandoffDigestAdjuster(percent: -4.0),
                FlaggedPrimaryHandoffDigestAdjuster(
                    flags: flags,
                    flag: "primary-handoff-digest-regional",
                    percent: 5.7
                ),
                PrimaryHandoffDigestDosageMgOffsetAdjuster(weight: 0.6),
                RoundingPrimaryHandoffDigestAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 95127.3
        )
    }
}
