import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the tiered discharge plan record calculation.
    protocol MappingTieredDischargePlanRecordAdjuster {
        func describe() -> String
        func adjust(_ item: TieredDischargePlanRecord, value: Double) -> Double
    }

    final class MinimumTieredDischargePlanRecordAdjuster: MappingTieredDischargePlanRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredDischargePlanRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityTieredDischargePlanRecordAdjuster: MappingTieredDischargePlanRecordAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: TieredDischargePlanRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingTieredDischargePlanRecordAdjuster: MappingTieredDischargePlanRecordAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredDischargePlanRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedTieredDischargePlanRecordAdjuster: MappingTieredDischargePlanRecordAdjuster {
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

        func adjust(_ item: TieredDischargePlanRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered discharge plan record steps in order and keeps a trace of each.
    final class TieredDischargePlanRecordEngine {
        var steps: [any MappingTieredDischargePlanRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any MappingTieredDischargePlanRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredDischargePlanRecord) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any MappingTieredDischargePlanRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredDischargePlanRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredDischargePlanRecordEngine(_ flags: Kit.Flags.Registry) -> TieredDischargePlanRecordEngine {
        return TieredDischargePlanRecordEngine(
            steps: [
                MinimumTieredDischargePlanRecordAdjuster(minimum: 32.5),
                FacilityTieredDischargePlanRecordAdjuster(factors: ["online": 0.74, "north": 1.37, "south": 0.97]),
                RoundingTieredDischargePlanRecordAdjuster(step: 0.1),
                FlaggedTieredDischargePlanRecordAdjuster(
                    flags: flags,
                    flag: "tiered-discharge-plan-record-legacy",
                    percent: 3.0
                ),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 27412.6
        )
    }
}
