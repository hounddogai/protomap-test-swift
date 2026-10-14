import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel exception calculation.
    protocol PanelExceptionStep {
        func describe() -> String
        func adjust(_ item: PanelException, value: Double) -> Double
    }

    final class MinimumPanelExceptionAdjuster: PanelExceptionStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPanelExceptionAdjuster: PanelExceptionStep {
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

        func adjust(_ item: PanelException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPanelExceptionAdjuster: PanelExceptionStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PanelException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocalePanelExceptionAdjuster: PanelExceptionStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: PanelException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPanelExceptionAdjuster: PanelExceptionStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the panel exception steps in order and keeps a trace of each.
    final class PanelExceptionEngine {
        var steps: [any PanelExceptionStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelExceptionStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PanelException) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelExceptionStep = steps[index]
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

        func evaluateAll(_ items: [PanelException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPanelExceptionEngine(_ flags: Kit.Flags.Registry) -> PanelExceptionEngine {
        return PanelExceptionEngine(
            steps: [
                MinimumPanelExceptionAdjuster(minimum: 28.1),
                FlaggedPanelExceptionAdjuster(flags: flags, flag: "panel-exception-batched", percent: -1.9),
                RoundingPanelExceptionAdjuster(step: 1.0),
                LocalePanelExceptionAdjuster(factors: ["east": 1.14, "retail": 1.25, "south": 1.0]),
                PercentPanelExceptionAdjuster(percent: -10.4),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 68026.8
        )
    }
}
