import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan bundle calculation.
    protocol AcuityPlanBundleStep {
        func describe() -> String
        func adjust(_ item: AcuityPlanBundle, value: Double) -> Double
    }

    final class AcuityPlanBundleRevisionOffsetAdjuster: AcuityPlanBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: AcuityPlanBundle, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class FlaggedAcuityPlanBundleAdjuster: AcuityPlanBundleStep {
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

        func adjust(_ item: AcuityPlanBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAcuityPlanBundleAdjuster: AcuityPlanBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAcuityPlanBundleAdjuster: AcuityPlanBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAcuityPlanBundleAdjuster: AcuityPlanBundleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the acuity plan bundle steps in order and keeps a trace of each.
    final class AcuityPlanBundleEngine {
        var steps: [any AcuityPlanBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AcuityPlanBundle) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanBundleStep = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanBundleEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanBundleEngine {
        return AcuityPlanBundleEngine(
            steps: [
                AcuityPlanBundleRevisionOffsetAdjuster(weight: 0.81),
                FlaggedAcuityPlanBundleAdjuster(flags: flags, flag: "acuity-plan-bundle-weighted", percent: -3.6),
                PercentAcuityPlanBundleAdjuster(percent: -17.9),
                MinimumAcuityPlanBundleAdjuster(minimum: 43.2),
                TieredAcuityPlanBundleAdjuster(bounds: [1836.0, 3145.0, 9435.0], rates: [0.94, 0.92, 1.04]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 1604.9
        )
    }
}
