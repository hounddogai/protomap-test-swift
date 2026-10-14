import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the fallback census metric calculation.
    protocol FallbackCensusMetricStep {
        func describe() -> String
        func adjust(_ item: FallbackCensusMetric, value: Double) -> Double
    }

    final class PercentFallbackCensusMetricAdjuster: FallbackCensusMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackCensusMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackCensusMetricAdjuster: FallbackCensusMetricStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackCensusMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFallbackCensusMetricAdjuster: FallbackCensusMetricStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCensusMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback census metric steps in order and keeps a trace of each.
    final class FallbackCensusMetricEngine {
        var steps: [any FallbackCensusMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCensusMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackCensusMetric) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [FallbackCensusMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackCensusMetricEngine() -> FallbackCensusMetricEngine {
        return FallbackCensusMetricEngine(
            steps: [
                PercentFallbackCensusMetricAdjuster(percent: -15.2),
                CapFallbackCensusMetricAdjuster(cap: 33004.0),
                RoundingFallbackCensusMetricAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 93826.5
        )
    }
}
