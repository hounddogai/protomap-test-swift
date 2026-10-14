import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality milestone calculation.
    protocol ModalityMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: ModalityMilestone, value: Double) -> Double
    }

    final class PercentModalityMilestoneAdjuster: ModalityMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalityMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumModalityMilestoneAdjuster: ModalityMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedModalityMilestoneAdjuster: ModalityMilestoneAdjuster {
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

        func adjust(_ item: ModalityMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapModalityMilestoneAdjuster: ModalityMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the modality milestone steps in order and keeps a trace of each.
    final class ModalityMilestoneEngine {
        var steps: [any ModalityMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ModalityMilestone) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [ModalityMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultModalityMilestoneEngine(_ flags: Kit.Flags.Registry) -> ModalityMilestoneEngine {
        return ModalityMilestoneEngine(
            steps: [
                PercentModalityMilestoneAdjuster(percent: -10.3),
                MinimumModalityMilestoneAdjuster(minimum: 24.8),
                FlaggedModalityMilestoneAdjuster(flags: flags, flag: "modality-milestone-capped", percent: -2.0),
                CapModalityMilestoneAdjuster(cap: 25712.0),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 18390.6
        )
    }
}
