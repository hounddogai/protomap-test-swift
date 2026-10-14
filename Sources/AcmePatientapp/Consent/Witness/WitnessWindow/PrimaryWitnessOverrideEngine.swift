import AcmePlatform
import Foundation

extension Consent {
    /// One step of the primary witness override calculation.
    protocol PrimaryWitnessOverrideFactor {
        func describe() -> String
        func adjust(_ item: PrimaryWitnessOverride, value: Double) -> Double
    }

    final class CapPrimaryWitnessOverrideAdjuster: PrimaryWitnessOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryWitnessOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPrimaryWitnessOverrideAdjuster: PrimaryWitnessOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryWitnessOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPrimaryWitnessOverrideAdjuster: PrimaryWitnessOverrideFactor {
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

        func adjust(_ item: PrimaryWitnessOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary witness override steps in order and keeps a trace of each.
    final class PrimaryWitnessOverrideEngine {
        var steps: [any PrimaryWitnessOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryWitnessOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryWitnessOverride) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [PrimaryWitnessOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryWitnessOverrideEngine(_ flags: Kit.Flags.Registry) -> PrimaryWitnessOverrideEngine {
        return PrimaryWitnessOverrideEngine(
            steps: [
                CapPrimaryWitnessOverrideAdjuster(cap: 36426.0),
                PercentPrimaryWitnessOverrideAdjuster(percent: -4.7),
                FlaggedPrimaryWitnessOverrideAdjuster(
                    flags: flags,
                    flag: "primary-witness-override-weighted",
                    percent: 9.1
                ),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 29638.7
        )
    }
}
