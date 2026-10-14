import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default cleaning manifest calculation.
    protocol DefaultCleaningManifestFactor {
        func describe() -> String
        func adjust(_ item: DefaultCleaningManifest, value: Double) -> Double
    }

    final class PercentDefaultCleaningManifestAdjuster: DefaultCleaningManifestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCleaningManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultCleaningManifestAdjuster: DefaultCleaningManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultCleaningManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDefaultCleaningManifestAdjuster: DefaultCleaningManifestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultCleaningManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDefaultCleaningManifestAdjuster: DefaultCleaningManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCleaningManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelDefaultCleaningManifestAdjuster: DefaultCleaningManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DefaultCleaningManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDefaultCleaningManifestAdjuster: DefaultCleaningManifestFactor {
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

        func adjust(_ item: DefaultCleaningManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default cleaning manifest steps in order and keeps a trace of each.
    final class DefaultCleaningManifestEngine {
        var steps: [any DefaultCleaningManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCleaningManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultCleaningManifest) -> Double {
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

        func evaluateAll(_ items: [DefaultCleaningManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultCleaningManifestEngine(_ flags: Kit.Flags.Registry) -> DefaultCleaningManifestEngine {
        return DefaultCleaningManifestEngine(
            steps: [
                PercentDefaultCleaningManifestAdjuster(percent: 24.3),
                RoundingDefaultCleaningManifestAdjuster(step: 0.05),
                CapDefaultCleaningManifestAdjuster(cap: 24517.0),
                TieredDefaultCleaningManifestAdjuster(
                    bounds: [846.0, 2585.0, 3041.0, 4352.0],
                    rates: [0.95, 1.04, 1.14, 0.86]
                ),
                LabelDefaultCleaningManifestAdjuster(factors: ["west": 1.06]),
                FlaggedDefaultCleaningManifestAdjuster(
                    flags: flags,
                    flag: "default-cleaning-manifest-primary",
                    percent: -6.7
                ),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 82032.5
        )
    }
}
