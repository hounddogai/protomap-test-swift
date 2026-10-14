import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy checkpoint calculation.
    protocol ProxyCheckpointFactor {
        func describe() -> String
        func adjust(_ item: ProxyCheckpoint, value: Double) -> Double
    }

    final class FlaggedProxyCheckpointAdjuster: ProxyCheckpointFactor {
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

        func adjust(_ item: ProxyCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleProxyCheckpointAdjuster: ProxyCheckpointFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ProxyCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingProxyCheckpointAdjuster: ProxyCheckpointFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the proxy checkpoint steps in order and keeps a trace of each.
    final class ProxyCheckpointEngine {
        var steps: [any ProxyCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ProxyCheckpoint) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [ProxyCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultProxyCheckpointEngine(_ flags: Kit.Flags.Registry) -> ProxyCheckpointEngine {
        return ProxyCheckpointEngine(
            steps: [
                FlaggedProxyCheckpointAdjuster(flags: flags, flag: "proxy-checkpoint-fallback", percent: -3.0),
                LocaleProxyCheckpointAdjuster(factors: ["central": 0.98]),
                RoundingProxyCheckpointAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 35338.3
        )
    }
}
