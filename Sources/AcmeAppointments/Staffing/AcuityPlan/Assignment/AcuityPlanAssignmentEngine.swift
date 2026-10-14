import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan assignment calculation.
    protocol AcuityPlanAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: AcuityPlanAssignment, value: Double) -> Double
    }

    final class AcuityPlanAssignmentWindowDaysOffsetAdjuster: AcuityPlanAssignmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: AcuityPlanAssignment, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class RoundingAcuityPlanAssignmentAdjuster: AcuityPlanAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAcuityPlanAssignmentAdjuster: AcuityPlanAssignmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAcuityPlanAssignmentAdjuster: AcuityPlanAssignmentAdjuster {
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

        func adjust(_ item: AcuityPlanAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the acuity plan assignment steps in order and keeps a trace of each.
    final class AcuityPlanAssignmentEngine {
        var steps: [any AcuityPlanAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AcuityPlanAssignment) -> Double {
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

        func evaluateAll(_ items: [AcuityPlanAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanAssignmentEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanAssignmentEngine {
        return AcuityPlanAssignmentEngine(
            steps: [
                AcuityPlanAssignmentWindowDaysOffsetAdjuster(weight: 0.02),
                RoundingAcuityPlanAssignmentAdjuster(step: 0.05),
                TieredAcuityPlanAssignmentAdjuster(
                    bounds: [1005.0, 1441.0, 2444.0, 5608.0],
                    rates: [1.05, 1.17, 1.19, 0.87]
                ),
                FlaggedAcuityPlanAssignmentAdjuster(
                    flags: flags,
                    flag: "acuity-plan-assignment-fallback",
                    percent: -6.5
                ),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 31069.5
        )
    }
}
