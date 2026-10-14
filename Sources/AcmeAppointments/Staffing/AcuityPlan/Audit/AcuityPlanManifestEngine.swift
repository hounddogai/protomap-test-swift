import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan manifest calculation.
    protocol AcuityPlanManifestModifier {
        func describe() -> String
        func adjust(_ item: AcuityPlanManifest, value: Double) -> Double
    }

    final class MinimumAcuityPlanManifestAdjuster: AcuityPlanManifestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAcuityPlanManifestAdjuster: AcuityPlanManifestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAcuityPlanManifestAdjuster: AcuityPlanManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAcuityPlanManifestAdjuster: AcuityPlanManifestModifier {
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

        func adjust(_ item: AcuityPlanManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the acuity plan manifest steps in order and keeps a trace of each.
    final class AcuityPlanManifestEngine {
        var steps: [any AcuityPlanManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AcuityPlanManifest) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanManifestModifier = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanManifestEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanManifestEngine {
        return AcuityPlanManifestEngine(
            steps: [
                MinimumAcuityPlanManifestAdjuster(minimum: 45.8),
                TieredAcuityPlanManifestAdjuster(bounds: [75.0, 6650.0], rates: [0.83, 1.0]),
                CapAcuityPlanManifestAdjuster(cap: 14800.0),
                FlaggedAcuityPlanManifestAdjuster(flags: flags, flag: "acuity-plan-manifest-tiered", percent: -5.0),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 88543.9
        )
    }
}
