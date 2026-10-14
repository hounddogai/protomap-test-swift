import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction manifest calculation.
    protocol InteractionManifestModifier {
        func describe() -> String
        func adjust(_ item: InteractionManifest, value: Double) -> Double
    }

    final class InteractionManifestGraceDaysOffsetAdjuster: InteractionManifestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: InteractionManifest, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class MinimumInteractionManifestAdjuster: InteractionManifestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityInteractionManifestAdjuster: InteractionManifestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: InteractionManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredInteractionManifestAdjuster: InteractionManifestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapInteractionManifestAdjuster: InteractionManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the interaction manifest steps in order and keeps a trace of each.
    final class InteractionManifestEngine {
        var steps: [any InteractionManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: InteractionManifest) -> Double {
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

        func evaluateAll(_ items: [InteractionManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultInteractionManifestEngine() -> InteractionManifestEngine {
        return InteractionManifestEngine(
            steps: [
                InteractionManifestGraceDaysOffsetAdjuster(weight: 0.9),
                MinimumInteractionManifestAdjuster(minimum: 31.9),
                FacilityInteractionManifestAdjuster(factors: ["central": 1.1]),
                TieredInteractionManifestAdjuster(bounds: [3053.0, 4480.0, 9443.0], rates: [0.85, 0.96, 1.02]),
                CapInteractionManifestAdjuster(cap: 4827.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 77794.5
        )
    }
}
