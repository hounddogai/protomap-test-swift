import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the legacy acuity plan mapping calculation.
    protocol LegacyAcuityPlanMappingAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyAcuityPlanMapping, value: Double) -> Double
    }

    final class LegacyAcuityPlanMappingQuantityOffsetAdjuster: LegacyAcuityPlanMappingAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: LegacyAcuityPlanMapping, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class FacilityLegacyAcuityPlanMappingAdjuster: LegacyAcuityPlanMappingAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: LegacyAcuityPlanMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLegacyAcuityPlanMappingAdjuster: LegacyAcuityPlanMappingAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyAcuityPlanMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLegacyAcuityPlanMappingAdjuster: LegacyAcuityPlanMappingAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyAcuityPlanMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLegacyAcuityPlanMappingAdjuster: LegacyAcuityPlanMappingAdjuster {
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

        func adjust(_ item: LegacyAcuityPlanMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy acuity plan mapping steps in order and keeps a trace of each.
    final class LegacyAcuityPlanMappingEngine {
        var steps: [any LegacyAcuityPlanMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAcuityPlanMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyAcuityPlanMapping) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [LegacyAcuityPlanMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyAcuityPlanMappingEngine(_ flags: Kit.Flags.Registry) -> LegacyAcuityPlanMappingEngine {
        return LegacyAcuityPlanMappingEngine(
            steps: [
                LegacyAcuityPlanMappingQuantityOffsetAdjuster(weight: 1.91),
                FacilityLegacyAcuityPlanMappingAdjuster(factors: ["online": 1.19, "south": 1.3]),
                RoundingLegacyAcuityPlanMappingAdjuster(step: 0.25),
                PercentLegacyAcuityPlanMappingAdjuster(percent: 5.1),
                FlaggedLegacyAcuityPlanMappingAdjuster(
                    flags: flags,
                    flag: "legacy-acuity-plan-mapping-weighted",
                    percent: 2.4
                ),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 29075.9
        )
    }
}
