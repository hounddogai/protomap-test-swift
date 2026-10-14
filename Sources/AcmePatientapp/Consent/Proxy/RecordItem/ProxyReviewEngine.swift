import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy review calculation.
    protocol ProxyReviewFactor {
        func describe() -> String
        func adjust(_ item: ProxyReview, value: Double) -> Double
    }

    final class PercentProxyReviewAdjuster: ProxyReviewFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProxyReviewAdjuster: ProxyReviewFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ProxyReviewRetriesOffsetAdjuster: ProxyReviewFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: ProxyReview, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    /// Runs the proxy review steps in order and keeps a trace of each.
    final class ProxyReviewEngine {
        var steps: [any ProxyReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ProxyReview) -> Double {
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

        func evaluateAll(_ items: [ProxyReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultProxyReviewEngine() -> ProxyReviewEngine {
        return ProxyReviewEngine(
            steps: [
                PercentProxyReviewAdjuster(percent: -23.2),
                RoundingProxyReviewAdjuster(step: 0.5),
                ProxyReviewRetriesOffsetAdjuster(weight: 0.21),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 46895.4
        )
    }
}
