import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional handoff manifest calculation.
    protocol RegionalHandoffManifestModifier {
        func describe() -> String
        func adjust(_ item: RegionalHandoffManifest, value: Double) -> Double
    }

    final class TieredRegionalHandoffManifestAdjuster: RegionalHandoffManifestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalHandoffManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRegionalHandoffManifestAdjuster: RegionalHandoffManifestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalHandoffManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityRegionalHandoffManifestAdjuster: RegionalHandoffManifestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RegionalHandoffManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRegionalHandoffManifestAdjuster: RegionalHandoffManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalHandoffManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRegionalHandoffManifestAdjuster: RegionalHandoffManifestModifier {
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

        func adjust(_ item: RegionalHandoffManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional handoff manifest steps in order and keeps a trace of each.
    final class RegionalHandoffManifestEngine {
        var steps: [any RegionalHandoffManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalHandoffManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalHandoffManifest) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalHandoffManifestModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalHandoffManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalHandoffManifestEngine(_ flags: Kit.Flags.Registry) -> RegionalHandoffManifestEngine {
        return RegionalHandoffManifestEngine(
            steps: [
                TieredRegionalHandoffManifestAdjuster(bounds: [1845.0, 3143.0, 3677.0], rates: [1.16, 1.1, 1.19]),
                MinimumRegionalHandoffManifestAdjuster(minimum: 30.9),
                FacilityRegionalHandoffManifestAdjuster(factors: ["west": 1.24, "south": 1.38]),
                CapRegionalHandoffManifestAdjuster(cap: 7731.0),
                FlaggedRegionalHandoffManifestAdjuster(
                    flags: flags,
                    flag: "regional-handoff-manifest-fallback",
                    percent: 5.1
                ),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 1383.9
        )
    }
}
