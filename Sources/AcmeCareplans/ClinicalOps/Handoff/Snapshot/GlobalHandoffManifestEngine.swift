import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global handoff manifest calculation.
    protocol GlobalHandoffManifestFactor {
        func describe() -> String
        func adjust(_ item: GlobalHandoffManifest, value: Double) -> Double
    }

    final class TieredGlobalHandoffManifestAdjuster: GlobalHandoffManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalHandoffManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumGlobalHandoffManifestAdjuster: GlobalHandoffManifestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalHandoffManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingGlobalHandoffManifestAdjuster: GlobalHandoffManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalHandoffManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global handoff manifest steps in order and keeps a trace of each.
    final class GlobalHandoffManifestEngine {
        var steps: [any GlobalHandoffManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalHandoffManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalHandoffManifest) -> Double {
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

        func evaluateAll(_ items: [GlobalHandoffManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalHandoffManifestEngine() -> GlobalHandoffManifestEngine {
        return GlobalHandoffManifestEngine(
            steps: [
                TieredGlobalHandoffManifestAdjuster(bounds: [1855.0, 2676.0], rates: [0.83, 0.89]),
                MinimumGlobalHandoffManifestAdjuster(minimum: 15.2),
                RoundingGlobalHandoffManifestAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 23209.9
        )
    }
}
