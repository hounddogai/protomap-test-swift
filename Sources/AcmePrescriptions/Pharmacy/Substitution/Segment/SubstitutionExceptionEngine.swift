import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution exception calculation.
    protocol SubstitutionExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: SubstitutionException, value: Double) -> Double
    }

    final class RoundingSubstitutionExceptionAdjuster: SubstitutionExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SubstitutionException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSubstitutionExceptionAdjuster: SubstitutionExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSubstitutionExceptionAdjuster: SubstitutionExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SubstitutionException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapSubstitutionExceptionAdjuster: SubstitutionExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SubstitutionException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SubstitutionExceptionFloorValueOffsetAdjuster: SubstitutionExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: SubstitutionException, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    /// Runs the substitution exception steps in order and keeps a trace of each.
    final class SubstitutionExceptionEngine {
        var steps: [any SubstitutionExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SubstitutionException) -> Double {
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

        func evaluateAll(_ items: [SubstitutionException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSubstitutionExceptionEngine() -> SubstitutionExceptionEngine {
        return SubstitutionExceptionEngine(
            steps: [
                RoundingSubstitutionExceptionAdjuster(step: 0.05),
                PercentSubstitutionExceptionAdjuster(percent: 20.8),
                TieredSubstitutionExceptionAdjuster(bounds: [6842.0, 7464.0], rates: [0.95, 1.03]),
                CapSubstitutionExceptionAdjuster(cap: 25740.0),
                SubstitutionExceptionFloorValueOffsetAdjuster(weight: 1.6),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 1212.3
        )
    }
}
