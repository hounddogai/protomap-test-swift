import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy score calculation.
    protocol ProxyScoreFactor {
        func describe() -> String
        func adjust(_ item: ProxyScore, value: Double) -> Double
    }

    final class FlaggedProxyScoreAdjuster: ProxyScoreFactor {
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

        func adjust(_ item: ProxyScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentProxyScoreAdjuster: ProxyScoreFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProxyScoreAdjuster: ProxyScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the proxy score steps in order and keeps a trace of each.
    final class ProxyScoreEngine {
        var steps: [any ProxyScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProxyScore) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ProxyScoreFactor = steps[index]
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

        func evaluateAll(_ items: [ProxyScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProxyScoreEngine(_ flags: Kit.Flags.Registry) -> ProxyScoreEngine {
        return ProxyScoreEngine(
            steps: [
                FlaggedProxyScoreAdjuster(flags: flags, flag: "proxy-score-tiered", percent: -1.2),
                PercentProxyScoreAdjuster(percent: 9.5),
                RoundingProxyScoreAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 78214.9
        )
    }
}
