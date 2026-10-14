import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive credential mapping calculation.
    protocol AdaptiveCredentialMappingModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveCredentialMapping, value: Double) -> Double
    }

    final class CapAdaptiveCredentialMappingAdjuster: AdaptiveCredentialMappingModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveCredentialMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AdaptiveCredentialMappingEndsAtOffsetAdjuster: AdaptiveCredentialMappingModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: AdaptiveCredentialMapping, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class TieredAdaptiveCredentialMappingAdjuster: AdaptiveCredentialMappingModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveCredentialMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAdaptiveCredentialMappingAdjuster: AdaptiveCredentialMappingModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveCredentialMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive credential mapping steps in order and keeps a trace of each.
    final class AdaptiveCredentialMappingEngine {
        var steps: [any AdaptiveCredentialMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveCredentialMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveCredentialMapping) -> Double {
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

        func evaluateAll(_ items: [AdaptiveCredentialMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveCredentialMappingEngine() -> AdaptiveCredentialMappingEngine {
        return AdaptiveCredentialMappingEngine(
            steps: [
                CapAdaptiveCredentialMappingAdjuster(cap: 44023.0),
                AdaptiveCredentialMappingEndsAtOffsetAdjuster(weight: 0.12),
                TieredAdaptiveCredentialMappingAdjuster(bounds: [1409.0, 5042.0, 6940.0], rates: [0.97, 0.98, 1.12]),
                MinimumAdaptiveCredentialMappingAdjuster(minimum: 6.2),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 69336.1
        )
    }
}
