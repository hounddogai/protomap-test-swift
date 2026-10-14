import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback accession threshold calculation.
    protocol FallbackAccessionThresholdFactor {
        func describe() -> String
        func adjust(_ item: FallbackAccessionThreshold, value: Double) -> Double
    }

    final class SegmentFallbackAccessionThresholdAdjuster: FallbackAccessionThresholdFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: FallbackAccessionThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackAccessionThresholdAdjuster: FallbackAccessionThresholdFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackAccessionThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapFallbackAccessionThresholdAdjuster: FallbackAccessionThresholdFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackAccessionThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback accession threshold steps in order and keeps a trace of each.
    final class FallbackAccessionThresholdEngine {
        var steps: [any FallbackAccessionThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAccessionThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackAccessionThreshold) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [FallbackAccessionThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackAccessionThresholdEngine() -> FallbackAccessionThresholdEngine {
        return FallbackAccessionThresholdEngine(
            steps: [
                SegmentFallbackAccessionThresholdAdjuster(factors: ["south": 1.23, "west": 1.24]),
                MinimumFallbackAccessionThresholdAdjuster(minimum: 23.1),
                CapFallbackAccessionThresholdAdjuster(cap: 42259.0),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 79912.3
        )
    }
}
