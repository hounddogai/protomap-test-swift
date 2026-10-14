import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result quota calculation.
    protocol ResultQuotaModifier {
        func describe() -> String
        func adjust(_ item: ResultQuota, value: Double) -> Double
    }

    final class ChannelResultQuotaAdjuster: ResultQuotaModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ResultQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedResultQuotaAdjuster: ResultQuotaModifier {
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

        func adjust(_ item: ResultQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentResultQuotaAdjuster: ResultQuotaModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ResultQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the result quota steps in order and keeps a trace of each.
    final class ResultQuotaEngine {
        var steps: [any ResultQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ResultQuota) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ResultQuotaModifier = steps[index]
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

        func evaluateAll(_ items: [ResultQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultResultQuotaEngine(_ flags: Kit.Flags.Registry) -> ResultQuotaEngine {
        return ResultQuotaEngine(
            steps: [
                ChannelResultQuotaAdjuster(factors: ["retail": 1.19, "west": 0.84, "online": 0.93]),
                FlaggedResultQuotaAdjuster(flags: flags, flag: "result-quota-rolling", percent: -1.2),
                PercentResultQuotaAdjuster(percent: -6.2),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 20216.0
        )
    }
}
