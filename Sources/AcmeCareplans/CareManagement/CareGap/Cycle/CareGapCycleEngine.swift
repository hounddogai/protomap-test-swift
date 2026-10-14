import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap cycle calculation.
    protocol CareGapCycleModifier {
        func describe() -> String
        func adjust(_ item: CareGapCycle, value: Double) -> Double
    }

    final class FlaggedCareGapCycleAdjuster: CareGapCycleModifier {
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

        func adjust(_ item: CareGapCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CareGapCycleFloorValueOffsetAdjuster: CareGapCycleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: CareGapCycle, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class TieredCareGapCycleAdjuster: CareGapCycleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCareGapCycleAdjuster: CareGapCycleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleCareGapCycleAdjuster: CareGapCycleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CareGapCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCareGapCycleAdjuster: CareGapCycleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the care gap cycle steps in order and keeps a trace of each.
    final class CareGapCycleEngine {
        var steps: [any CareGapCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareGapCycle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapCycleModifier = steps[index]
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

        func evaluateAll(_ items: [CareGapCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareGapCycleEngine(_ flags: Kit.Flags.Registry) -> CareGapCycleEngine {
        return CareGapCycleEngine(
            steps: [
                FlaggedCareGapCycleAdjuster(flags: flags, flag: "care-gap-cycle-batched", percent: 9.2),
                CareGapCycleFloorValueOffsetAdjuster(weight: 0.3),
                TieredCareGapCycleAdjuster(bounds: [8630.0, 8671.0], rates: [1.04, 0.91]),
                CapCareGapCycleAdjuster(cap: 45692.0),
                TitleCareGapCycleAdjuster(factors: ["south": 1.12, "west": 1.32, "online": 0.9]),
                RoundingCareGapCycleAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 67951.4
        )
    }
}
