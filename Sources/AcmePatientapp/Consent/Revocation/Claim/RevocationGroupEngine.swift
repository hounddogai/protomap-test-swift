import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation group calculation.
    protocol RevocationGroupAdjuster {
        func describe() -> String
        func adjust(_ item: RevocationGroup, value: Double) -> Double
    }

    final class TieredRevocationGroupAdjuster: RevocationGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RevocationGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRevocationGroupAdjuster: RevocationGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RevocationGroupQuantityOffsetAdjuster: RevocationGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: RevocationGroup, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class WardRevocationGroupAdjuster: RevocationGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: RevocationGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRevocationGroupAdjuster: RevocationGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the revocation group steps in order and keeps a trace of each.
    final class RevocationGroupEngine {
        var steps: [any RevocationGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RevocationGroup) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [RevocationGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRevocationGroupEngine() -> RevocationGroupEngine {
        return RevocationGroupEngine(
            steps: [
                TieredRevocationGroupAdjuster(bounds: [3276.0, 3506.0, 6405.0], rates: [1.07, 1.2, 1.19]),
                RoundingRevocationGroupAdjuster(step: 0.05),
                RevocationGroupQuantityOffsetAdjuster(weight: 0.78),
                WardRevocationGroupAdjuster(factors: ["south": 1.38, "north": 1.01]),
                CapRevocationGroupAdjuster(cap: 46882.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 7605.2
        )
    }
}
