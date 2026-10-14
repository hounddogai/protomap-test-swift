import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback statement notice calculation.
    protocol FallbackStatementNoticeModifier {
        func describe() -> String
        func adjust(_ item: FallbackStatementNotice, value: Double) -> Double
    }

    final class PercentFallbackStatementNoticeAdjuster: FallbackStatementNoticeModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackStatementNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFallbackStatementNoticeAdjuster: FallbackStatementNoticeModifier {
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

        func adjust(_ item: FallbackStatementNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleFallbackStatementNoticeAdjuster: FallbackStatementNoticeModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: FallbackStatementNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback statement notice steps in order and keeps a trace of each.
    final class FallbackStatementNoticeEngine {
        var steps: [any FallbackStatementNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackStatementNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackStatementNotice) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackStatementNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackStatementNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackStatementNoticeEngine(_ flags: Kit.Flags.Registry) -> FallbackStatementNoticeEngine {
        return FallbackStatementNoticeEngine(
            steps: [
                PercentFallbackStatementNoticeAdjuster(percent: 10.1),
                FlaggedFallbackStatementNoticeAdjuster(
                    flags: flags,
                    flag: "fallback-statement-notice-default",
                    percent: -9.5
                ),
                LocaleFallbackStatementNoticeAdjuster(factors: ["retail": 1.29, "online": 1.21]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 21371.0
        )
    }
}
