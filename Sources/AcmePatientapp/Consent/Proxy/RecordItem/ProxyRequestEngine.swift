import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy request calculation.
    protocol ProxyRequestStep {
        func describe() -> String
        func adjust(_ item: ProxyRequest, value: Double) -> Double
    }

    final class FlaggedProxyRequestAdjuster: ProxyRequestStep {
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

        func adjust(_ item: ProxyRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityProxyRequestAdjuster: ProxyRequestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ProxyRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumProxyRequestAdjuster: ProxyRequestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the proxy request steps in order and keeps a trace of each.
    final class ProxyRequestEngine {
        var steps: [any ProxyRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProxyRequest) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ProxyRequestStep = steps[index]
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

        func evaluateAll(_ items: [ProxyRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProxyRequestEngine(_ flags: Kit.Flags.Registry) -> ProxyRequestEngine {
        return ProxyRequestEngine(
            steps: [
                FlaggedProxyRequestAdjuster(flags: flags, flag: "proxy-request-regional", percent: -9.7),
                FacilityProxyRequestAdjuster(factors: ["east": 0.86, "retail": 1.05, "west": 0.93]),
                MinimumProxyRequestAdjuster(minimum: 24.6),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 64156.2
        )
    }
}
