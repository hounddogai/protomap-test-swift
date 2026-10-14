import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict acuity plan bundle calculation.
    protocol StrictAcuityPlanBundleModifier {
        func describe() -> String
        func adjust(_ item: StrictAcuityPlanBundle, value: Double) -> Double
    }

    final class FlaggedStrictAcuityPlanBundleAdjuster: StrictAcuityPlanBundleModifier {
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

        func adjust(_ item: StrictAcuityPlanBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitStrictAcuityPlanBundleAdjuster: StrictAcuityPlanBundleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: StrictAcuityPlanBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class StrictAcuityPlanBundleUpdatedAtOffsetAdjuster: StrictAcuityPlanBundleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: StrictAcuityPlanBundle, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the strict acuity plan bundle steps in order and keeps a trace of each.
    final class StrictAcuityPlanBundleEngine {
        var steps: [any StrictAcuityPlanBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictAcuityPlanBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictAcuityPlanBundle) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [StrictAcuityPlanBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictAcuityPlanBundleEngine(_ flags: Kit.Flags.Registry) -> StrictAcuityPlanBundleEngine {
        return StrictAcuityPlanBundleEngine(
            steps: [
                FlaggedStrictAcuityPlanBundleAdjuster(
                    flags: flags,
                    flag: "strict-acuity-plan-bundle-strict",
                    percent: -4.3
                ),
                UnitStrictAcuityPlanBundleAdjuster(factors: ["east": 1.33, "online": 1.16, "south": 0.73]),
                StrictAcuityPlanBundleUpdatedAtOffsetAdjuster(weight: 0.89),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 3522.6
        )
    }
}
