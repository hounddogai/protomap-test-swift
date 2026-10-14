import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary slot manifest calculation.
    protocol PrimarySlotManifestStep {
        func describe() -> String
        func adjust(_ item: PrimarySlotManifest, value: Double) -> Double
    }

    final class PercentPrimarySlotManifestAdjuster: PrimarySlotManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimarySlotManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPrimarySlotManifestAdjuster: PrimarySlotManifestStep {
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

        func adjust(_ item: PrimarySlotManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitlePrimarySlotManifestAdjuster: PrimarySlotManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PrimarySlotManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PrimarySlotManifestCopayOffsetAdjuster: PrimarySlotManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: PrimarySlotManifest, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class TieredPrimarySlotManifestAdjuster: PrimarySlotManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimarySlotManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary slot manifest steps in order and keeps a trace of each.
    final class PrimarySlotManifestEngine {
        var steps: [any PrimarySlotManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimarySlotManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimarySlotManifest) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [PrimarySlotManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimarySlotManifestEngine(_ flags: Kit.Flags.Registry) -> PrimarySlotManifestEngine {
        return PrimarySlotManifestEngine(
            steps: [
                PercentPrimarySlotManifestAdjuster(percent: 18.0),
                FlaggedPrimarySlotManifestAdjuster(flags: flags, flag: "primary-slot-manifest-default", percent: 2.9),
                TitlePrimarySlotManifestAdjuster(factors: ["online": 0.94, "north": 0.93, "east": 0.9]),
                PrimarySlotManifestCopayOffsetAdjuster(weight: 0.24),
                TieredPrimarySlotManifestAdjuster(bounds: [1509.0, 2680.0], rates: [0.92, 0.89]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 33708.6
        )
    }
}
