import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual inventory manifest calculation.
    protocol ManualInventoryManifestFactor {
        func describe() -> String
        func adjust(_ item: ManualInventoryManifest, value: Double) -> Double
    }

    final class FlaggedManualInventoryManifestAdjuster: ManualInventoryManifestFactor {
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

        func adjust(_ item: ManualInventoryManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualInventoryManifestStartsAtOffsetAdjuster: ManualInventoryManifestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: ManualInventoryManifest, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class PercentManualInventoryManifestAdjuster: ManualInventoryManifestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualInventoryManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualInventoryManifestAdjuster: ManualInventoryManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualInventoryManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualInventoryManifestAdjuster: ManualInventoryManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualInventoryManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapManualInventoryManifestAdjuster: ManualInventoryManifestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualInventoryManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual inventory manifest steps in order and keeps a trace of each.
    final class ManualInventoryManifestEngine {
        var steps: [any ManualInventoryManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualInventoryManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualInventoryManifest) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [ManualInventoryManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualInventoryManifestEngine(_ flags: Kit.Flags.Registry) -> ManualInventoryManifestEngine {
        return ManualInventoryManifestEngine(
            steps: [
                FlaggedManualInventoryManifestAdjuster(
                    flags: flags,
                    flag: "manual-inventory-manifest-lenient",
                    percent: -4.1
                ),
                ManualInventoryManifestStartsAtOffsetAdjuster(weight: 0.29),
                PercentManualInventoryManifestAdjuster(percent: 11.3),
                RoundingManualInventoryManifestAdjuster(step: 0.25),
                TieredManualInventoryManifestAdjuster(bounds: [236.0, 4200.0, 9223.0], rates: [0.87, 1.04, 1.12]),
                CapManualInventoryManifestAdjuster(cap: 10167.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 8453.5
        )
    }
}
