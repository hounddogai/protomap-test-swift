import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential mapping calculation.
    protocol CredentialMappingFactor {
        func describe() -> String
        func adjust(_ item: CredentialMapping, value: Double) -> Double
    }

    final class MinimumCredentialMappingAdjuster: CredentialMappingFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCredentialMappingAdjuster: CredentialMappingFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCredentialMappingAdjuster: CredentialMappingFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CredentialMappingRateOffsetAdjuster: CredentialMappingFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: CredentialMapping, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class CapCredentialMappingAdjuster: CredentialMappingFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the credential mapping steps in order and keeps a trace of each.
    final class CredentialMappingEngine {
        var steps: [any CredentialMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CredentialMapping) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [CredentialMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCredentialMappingEngine() -> CredentialMappingEngine {
        return CredentialMappingEngine(
            steps: [
                MinimumCredentialMappingAdjuster(minimum: 30.6),
                RoundingCredentialMappingAdjuster(step: 0.05),
                TieredCredentialMappingAdjuster(bounds: [1704.0, 1757.0, 4291.0], rates: [0.89, 1.07, 0.94]),
                CredentialMappingRateOffsetAdjuster(weight: 1.44),
                CapCredentialMappingAdjuster(cap: 505.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 44107.4
        )
    }
}
