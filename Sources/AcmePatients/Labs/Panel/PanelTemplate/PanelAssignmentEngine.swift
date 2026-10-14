import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel assignment calculation.
    protocol PanelAssignmentStep {
        func describe() -> String
        func adjust(_ item: PanelAssignment, value: Double) -> Double
    }

    final class MinimumPanelAssignmentAdjuster: PanelAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPanelAssignmentAdjuster: PanelAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PanelAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPanelAssignmentAdjuster: PanelAssignmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitlePanelAssignmentAdjuster: PanelAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PanelAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPanelAssignmentAdjuster: PanelAssignmentStep {
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

        func adjust(_ item: PanelAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the panel assignment steps in order and keeps a trace of each.
    final class PanelAssignmentEngine {
        var steps: [any PanelAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PanelAssignment) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelAssignmentStep = steps[index]
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

        func evaluateAll(_ items: [PanelAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPanelAssignmentEngine(_ flags: Kit.Flags.Registry) -> PanelAssignmentEngine {
        return PanelAssignmentEngine(
            steps: [
                MinimumPanelAssignmentAdjuster(minimum: 9.2),
                TieredPanelAssignmentAdjuster(bounds: [6449.0, 7524.0], rates: [0.89, 1.15]),
                CapPanelAssignmentAdjuster(cap: 28891.0),
                TitlePanelAssignmentAdjuster(factors: ["north": 1.22]),
                FlaggedPanelAssignmentAdjuster(flags: flags, flag: "panel-assignment-fallback", percent: -9.8),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 92346.8
        )
    }
}
