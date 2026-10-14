import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the global denial manifest calculation.
    protocol GlobalDenialManifestModifier {
        func describe() -> String
        func adjust(_ item: GlobalDenialManifest, value: Double) -> Double
    }

    final class CapGlobalDenialManifestAdjuster: GlobalDenialManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalDenialManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentGlobalDenialManifestAdjuster: GlobalDenialManifestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalDenialManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedGlobalDenialManifestAdjuster: GlobalDenialManifestModifier {
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

        func adjust(_ item: GlobalDenialManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalDenialManifestAdjuster: GlobalDenialManifestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalDenialManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global denial manifest steps in order and keeps a trace of each.
    final class GlobalDenialManifestEngine {
        var steps: [any GlobalDenialManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalDenialManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalDenialManifest) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalDenialManifestModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalDenialManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalDenialManifestEngine(_ flags: Kit.Flags.Registry) -> GlobalDenialManifestEngine {
        return GlobalDenialManifestEngine(
            steps: [
                CapGlobalDenialManifestAdjuster(cap: 5491.0),
                PercentGlobalDenialManifestAdjuster(percent: 15.2),
                FlaggedGlobalDenialManifestAdjuster(
                    flags: flags,
                    flag: "global-denial-manifest-fallback",
                    percent: -2.6
                ),
                TieredGlobalDenialManifestAdjuster(
                    bounds: [1372.0, 3545.0, 3560.0, 3957.0],
                    rates: [1.07, 1.0, 1.03, 1.11]
                ),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 12754.3
        )
    }
}
