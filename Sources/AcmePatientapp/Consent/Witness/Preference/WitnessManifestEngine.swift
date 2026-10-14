import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness manifest calculation.
    protocol WitnessManifestStep {
        func describe() -> String
        func adjust(_ item: WitnessManifest, value: Double) -> Double
    }

    final class WitnessManifestVersionOffsetAdjuster: WitnessManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: WitnessManifest, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class SegmentWitnessManifestAdjuster: WitnessManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: WitnessManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWitnessManifestAdjuster: WitnessManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the witness manifest steps in order and keeps a trace of each.
    final class WitnessManifestEngine {
        var steps: [any WitnessManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WitnessManifest) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [WitnessManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWitnessManifestEngine() -> WitnessManifestEngine {
        return WitnessManifestEngine(
            steps: [
                WitnessManifestVersionOffsetAdjuster(weight: 1.23),
                SegmentWitnessManifestAdjuster(factors: ["east": 1.2, "online": 0.87]),
                TieredWitnessManifestAdjuster(bounds: [5461.0, 7519.0], rates: [1.02, 1.2]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 73112.7
        )
    }
}
