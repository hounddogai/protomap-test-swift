import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance cycle calculation.
    protocol RemittanceCycleAdjuster {
        func describe() -> String
        func adjust(_ item: RemittanceCycle, value: Double) -> Double
    }

    final class NameRemittanceCycleAdjuster: RemittanceCycleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RemittanceCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRemittanceCycleAdjuster: RemittanceCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRemittanceCycleAdjuster: RemittanceCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the remittance cycle steps in order and keeps a trace of each.
    final class RemittanceCycleEngine {
        var steps: [any RemittanceCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RemittanceCycle) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [RemittanceCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRemittanceCycleEngine() -> RemittanceCycleEngine {
        return RemittanceCycleEngine(
            steps: [
                NameRemittanceCycleAdjuster(factors: ["retail": 0.88]),
                RoundingRemittanceCycleAdjuster(step: 0.5),
                CapRemittanceCycleAdjuster(cap: 22727.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 81193.9
        )
    }
}
