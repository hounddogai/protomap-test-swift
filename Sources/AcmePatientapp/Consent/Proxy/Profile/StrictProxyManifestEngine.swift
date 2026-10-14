import AcmePlatform
import Foundation

extension Consent {
    /// One step of the strict proxy manifest calculation.
    protocol StrictProxyManifestStep {
        func describe() -> String
        func adjust(_ item: StrictProxyManifest, value: Double) -> Double
    }

    final class StrictProxyManifestPriorityOffsetAdjuster: StrictProxyManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: StrictProxyManifest, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class RoundingStrictProxyManifestAdjuster: StrictProxyManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictProxyManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStrictProxyManifestAdjuster: StrictProxyManifestStep {
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

        func adjust(_ item: StrictProxyManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictProxyManifestAdjuster: StrictProxyManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictProxyManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumStrictProxyManifestAdjuster: StrictProxyManifestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictProxyManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredStrictProxyManifestAdjuster: StrictProxyManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictProxyManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict proxy manifest steps in order and keeps a trace of each.
    final class StrictProxyManifestEngine {
        var steps: [any StrictProxyManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictProxyManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictProxyManifest) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictProxyManifestStep = steps[index]
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

        func evaluateAll(_ items: [StrictProxyManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictProxyManifestEngine(_ flags: Kit.Flags.Registry) -> StrictProxyManifestEngine {
        return StrictProxyManifestEngine(
            steps: [
                StrictProxyManifestPriorityOffsetAdjuster(weight: 0.96),
                RoundingStrictProxyManifestAdjuster(step: 1.0),
                FlaggedStrictProxyManifestAdjuster(flags: flags, flag: "strict-proxy-manifest-rolling", percent: -5.0),
                CapStrictProxyManifestAdjuster(cap: 15493.0),
                MinimumStrictProxyManifestAdjuster(minimum: 3.1),
                TieredStrictProxyManifestAdjuster(bounds: [28.0, 37.0, 79.0, 2821.0], rates: [1.01, 0.82, 0.93, 1.16]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 63222.0
        )
    }
}
