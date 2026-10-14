import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the pending care protocol exception calculation.
    protocol PendingCareProtocolExceptionStep {
        func describe() -> String
        func adjust(_ item: PendingCareProtocolException, value: Double) -> Double
    }

    final class PendingCareProtocolExceptionStartsAtOffsetAdjuster: PendingCareProtocolExceptionStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: PendingCareProtocolException, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class FlaggedPendingCareProtocolExceptionAdjuster: PendingCareProtocolExceptionStep {
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

        func adjust(_ item: PendingCareProtocolException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPendingCareProtocolExceptionAdjuster: PendingCareProtocolExceptionStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingCareProtocolException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPendingCareProtocolExceptionAdjuster: PendingCareProtocolExceptionStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingCareProtocolException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending care protocol exception steps in order and keeps a trace of each.
    final class PendingCareProtocolExceptionEngine {
        var steps: [any PendingCareProtocolExceptionStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCareProtocolExceptionStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingCareProtocolException) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [PendingCareProtocolException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingCareProtocolExceptionEngine(_ flags: Kit.Flags.Registry) -> PendingCareProtocolExceptionEngine {
        return PendingCareProtocolExceptionEngine(
            steps: [
                PendingCareProtocolExceptionStartsAtOffsetAdjuster(weight: 1.17),
                FlaggedPendingCareProtocolExceptionAdjuster(
                    flags: flags,
                    flag: "pending-care-protocol-exception-weighted",
                    percent: -2.3
                ),
                PercentPendingCareProtocolExceptionAdjuster(percent: 17.7),
                MinimumPendingCareProtocolExceptionAdjuster(minimum: 3.4),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 89540.4
        )
    }
}
