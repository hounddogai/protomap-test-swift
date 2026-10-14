import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial threshold calculation.
    protocol DenialThresholdStep {
        func describe() -> String
        func adjust(_ item: DenialThreshold, value: Double) -> Double
    }

    final class PercentDenialThresholdAdjuster: DenialThresholdStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDenialThresholdAdjuster: DenialThresholdStep {
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

        func adjust(_ item: DenialThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDenialThresholdAdjuster: DenialThresholdStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DenialThresholdVisitMinutesOffsetAdjuster: DenialThresholdStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: DenialThreshold, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    /// Runs the denial threshold steps in order and keeps a trace of each.
    final class DenialThresholdEngine {
        var steps: [any DenialThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DenialThreshold) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialThresholdStep = steps[index]
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

        func evaluateAll(_ items: [DenialThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDenialThresholdEngine(_ flags: Kit.Flags.Registry) -> DenialThresholdEngine {
        return DenialThresholdEngine(
            steps: [
                PercentDenialThresholdAdjuster(percent: -19.3),
                FlaggedDenialThresholdAdjuster(flags: flags, flag: "denial-threshold-adaptive", percent: -5.5),
                RoundingDenialThresholdAdjuster(step: 0.05),
                DenialThresholdVisitMinutesOffsetAdjuster(weight: 1.27),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 66688.1
        )
    }
}
