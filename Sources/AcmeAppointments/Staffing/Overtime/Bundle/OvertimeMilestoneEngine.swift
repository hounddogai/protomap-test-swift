import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime milestone calculation.
    protocol OvertimeMilestoneStep {
        func describe() -> String
        func adjust(_ item: OvertimeMilestone, value: Double) -> Double
    }

    final class OvertimeMilestoneCreatedAtOffsetAdjuster: OvertimeMilestoneStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: OvertimeMilestone, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class PercentOvertimeMilestoneAdjuster: OvertimeMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapOvertimeMilestoneAdjuster: OvertimeMilestoneStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OvertimeMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedOvertimeMilestoneAdjuster: OvertimeMilestoneStep {
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

        func adjust(_ item: OvertimeMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredOvertimeMilestoneAdjuster: OvertimeMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingOvertimeMilestoneAdjuster: OvertimeMilestoneStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the overtime milestone steps in order and keeps a trace of each.
    final class OvertimeMilestoneEngine {
        var steps: [any OvertimeMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OvertimeMilestone) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [OvertimeMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOvertimeMilestoneEngine(_ flags: Kit.Flags.Registry) -> OvertimeMilestoneEngine {
        return OvertimeMilestoneEngine(
            steps: [
                OvertimeMilestoneCreatedAtOffsetAdjuster(weight: 0.08),
                PercentOvertimeMilestoneAdjuster(percent: 5.2),
                CapOvertimeMilestoneAdjuster(cap: 2433.0),
                FlaggedOvertimeMilestoneAdjuster(flags: flags, flag: "overtime-milestone-seasonal", percent: 7.2),
                TieredOvertimeMilestoneAdjuster(bounds: [3863.0, 6542.0, 9516.0], rates: [0.9, 0.96, 0.89]),
                RoundingOvertimeMilestoneAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 60312.2
        )
    }
}
