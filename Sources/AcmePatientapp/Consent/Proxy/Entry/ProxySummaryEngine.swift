import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy summary calculation.
    protocol ProxySummaryAdjuster {
        func describe() -> String
        func adjust(_ item: ProxySummary, value: Double) -> Double
    }

    final class CapProxySummaryAdjuster: ProxySummaryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxySummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingProxySummaryAdjuster: ProxySummaryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxySummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentProxySummaryAdjuster: ProxySummaryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxySummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the proxy summary steps in order and keeps a trace of each.
    final class ProxySummaryEngine {
        var steps: [any ProxySummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxySummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProxySummary) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [ProxySummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProxySummaryEngine() -> ProxySummaryEngine {
        return ProxySummaryEngine(
            steps: [
                CapProxySummaryAdjuster(cap: 8509.0),
                RoundingProxySummaryAdjuster(step: 5.0),
                PercentProxySummaryAdjuster(percent: 1.6),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 30503.1
        )
    }
}
