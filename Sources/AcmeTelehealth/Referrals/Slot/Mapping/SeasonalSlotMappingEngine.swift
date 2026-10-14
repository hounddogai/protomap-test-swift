import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal slot mapping calculation.
    protocol SeasonalSlotMappingFactor {
        func describe() -> String
        func adjust(_ item: SeasonalSlotMapping, value: Double) -> Double
    }

    final class FlaggedSeasonalSlotMappingAdjuster: SeasonalSlotMappingFactor {
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

        func adjust(_ item: SeasonalSlotMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentSeasonalSlotMappingAdjuster: SeasonalSlotMappingFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalSlotMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalSlotMappingAdjuster: SeasonalSlotMappingFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalSlotMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSeasonalSlotMappingAdjuster: SeasonalSlotMappingFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalSlotMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal slot mapping steps in order and keeps a trace of each.
    final class SeasonalSlotMappingEngine {
        var steps: [any SeasonalSlotMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalSlotMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalSlotMapping) -> Double {
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

        func evaluateAll(_ items: [SeasonalSlotMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalSlotMappingEngine(_ flags: Kit.Flags.Registry) -> SeasonalSlotMappingEngine {
        return SeasonalSlotMappingEngine(
            steps: [
                FlaggedSeasonalSlotMappingAdjuster(flags: flags, flag: "seasonal-slot-mapping-primary", percent: 2.5),
                PercentSeasonalSlotMappingAdjuster(percent: 5.3),
                CapSeasonalSlotMappingAdjuster(cap: 29243.0),
                RoundingSeasonalSlotMappingAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 80205.0
        )
    }
}
