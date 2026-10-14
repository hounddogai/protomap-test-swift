import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped statement exception calculation.
    protocol CappedStatementExceptionStep {
        func describe() -> String
        func adjust(_ item: CappedStatementException, value: Double) -> Double
    }

    final class CappedStatementExceptionRevisionOffsetAdjuster: CappedStatementExceptionStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: CappedStatementException, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class TieredCappedStatementExceptionAdjuster: CappedStatementExceptionStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedStatementException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCappedStatementExceptionAdjuster: CappedStatementExceptionStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedStatementException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the capped statement exception steps in order and keeps a trace of each.
    final class CappedStatementExceptionEngine {
        var steps: [any CappedStatementExceptionStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedStatementExceptionStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedStatementException) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [CappedStatementException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedStatementExceptionEngine() -> CappedStatementExceptionEngine {
        return CappedStatementExceptionEngine(
            steps: [
                CappedStatementExceptionRevisionOffsetAdjuster(weight: 1.18),
                TieredCappedStatementExceptionAdjuster(bounds: [4296.0, 7211.0, 7721.0], rates: [0.81, 0.88, 0.85]),
                CapCappedStatementExceptionAdjuster(cap: 19653.0),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 84045.0
        )
    }
}
