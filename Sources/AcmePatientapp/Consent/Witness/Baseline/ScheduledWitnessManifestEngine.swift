import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled witness manifest calculation.
    protocol ScheduledWitnessManifestFactor {
        func describe() -> String
        func adjust(_ item: ScheduledWitnessManifest, value: Double) -> Double
    }

    final class CapScheduledWitnessManifestAdjuster: ScheduledWitnessManifestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledWitnessManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedScheduledWitnessManifestAdjuster: ScheduledWitnessManifestFactor {
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

        func adjust(_ item: ScheduledWitnessManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceScheduledWitnessManifestAdjuster: ScheduledWitnessManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ScheduledWitnessManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ScheduledWitnessManifestRevisionOffsetAdjuster: ScheduledWitnessManifestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: ScheduledWitnessManifest, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class TieredScheduledWitnessManifestAdjuster: ScheduledWitnessManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledWitnessManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled witness manifest steps in order and keeps a trace of each.
    final class ScheduledWitnessManifestEngine {
        var steps: [any ScheduledWitnessManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledWitnessManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledWitnessManifest) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ScheduledWitnessManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledWitnessManifestEngine(_ flags: Kit.Flags.Registry) -> ScheduledWitnessManifestEngine {
        return ScheduledWitnessManifestEngine(
            steps: [
                CapScheduledWitnessManifestAdjuster(cap: 30908.0),
                FlaggedScheduledWitnessManifestAdjuster(
                    flags: flags,
                    flag: "scheduled-witness-manifest-manual",
                    percent: -9.3
                ),
                SourceScheduledWitnessManifestAdjuster(factors: ["online": 0.96, "east": 1.4]),
                ScheduledWitnessManifestRevisionOffsetAdjuster(weight: 0.87),
                TieredScheduledWitnessManifestAdjuster(bounds: [5133.0, 8119.0], rates: [0.91, 1.14]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 70107.5
        )
    }
}
