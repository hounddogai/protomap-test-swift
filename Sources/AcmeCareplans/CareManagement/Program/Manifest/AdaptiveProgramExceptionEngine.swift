import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive program exception calculation.
    protocol AdaptiveProgramExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveProgramException, value: Double) -> Double
    }

    final class MinimumAdaptiveProgramExceptionAdjuster: AdaptiveProgramExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveProgramException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAdaptiveProgramExceptionAdjuster: AdaptiveProgramExceptionAdjuster {
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

        func adjust(_ item: AdaptiveProgramException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAdaptiveProgramExceptionAdjuster: AdaptiveProgramExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveProgramException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive program exception steps in order and keeps a trace of each.
    final class AdaptiveProgramExceptionEngine {
        var steps: [any AdaptiveProgramExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveProgramExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveProgramException) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveProgramExceptionAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveProgramException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveProgramExceptionEngine(_ flags: Kit.Flags.Registry) -> AdaptiveProgramExceptionEngine {
        return AdaptiveProgramExceptionEngine(
            steps: [
                MinimumAdaptiveProgramExceptionAdjuster(minimum: 9.6),
                FlaggedAdaptiveProgramExceptionAdjuster(
                    flags: flags,
                    flag: "adaptive-program-exception-global",
                    percent: -2.3
                ),
                PercentAdaptiveProgramExceptionAdjuster(percent: -24.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 32310.2
        )
    }
}
