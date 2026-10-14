import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict credential bundle calculation.
    protocol StrictCredentialBundleFactor {
        func describe() -> String
        func adjust(_ item: StrictCredentialBundle, value: Double) -> Double
    }

    final class RoundingStrictCredentialBundleAdjuster: StrictCredentialBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictCredentialBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStrictCredentialBundleAdjuster: StrictCredentialBundleFactor {
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

        func adjust(_ item: StrictCredentialBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictCredentialBundleAdjuster: StrictCredentialBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictCredentialBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameStrictCredentialBundleAdjuster: StrictCredentialBundleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StrictCredentialBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStrictCredentialBundleAdjuster: StrictCredentialBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictCredentialBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the strict credential bundle steps in order and keeps a trace of each.
    final class StrictCredentialBundleEngine {
        var steps: [any StrictCredentialBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCredentialBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictCredentialBundle) -> Double {
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

        func evaluateAll(_ items: [StrictCredentialBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictCredentialBundleEngine(_ flags: Kit.Flags.Registry) -> StrictCredentialBundleEngine {
        return StrictCredentialBundleEngine(
            steps: [
                RoundingStrictCredentialBundleAdjuster(step: 0.1),
                FlaggedStrictCredentialBundleAdjuster(
                    flags: flags,
                    flag: "strict-credential-bundle-regional",
                    percent: -1.5
                ),
                CapStrictCredentialBundleAdjuster(cap: 7239.0),
                NameStrictCredentialBundleAdjuster(factors: ["west": 1.21, "north": 1.06, "retail": 0.91]),
                MinimumStrictCredentialBundleAdjuster(minimum: 34.9),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 42170.9
        )
    }
}
