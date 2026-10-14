import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial manifest calculation.
    protocol DenialManifestAdjuster {
        func describe() -> String
        func adjust(_ item: DenialManifest, value: Double) -> Double
    }

    final class PercentDenialManifestAdjuster: DenialManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryDenialManifestAdjuster: DenialManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: DenialManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DenialManifestDosageMgOffsetAdjuster: DenialManifestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: DenialManifest, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class RoundingDenialManifestAdjuster: DenialManifestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDenialManifestAdjuster: DenialManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDenialManifestAdjuster: DenialManifestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the denial manifest steps in order and keeps a trace of each.
    final class DenialManifestEngine {
        var steps: [any DenialManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DenialManifest) -> Double {
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

        func evaluateAll(_ items: [DenialManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDenialManifestEngine() -> DenialManifestEngine {
        return DenialManifestEngine(
            steps: [
                PercentDenialManifestAdjuster(percent: 1.0),
                CategoryDenialManifestAdjuster(factors: ["south": 1.37, "online": 1.23, "east": 0.88]),
                DenialManifestDosageMgOffsetAdjuster(weight: 1.39),
                RoundingDenialManifestAdjuster(step: 0.5),
                CapDenialManifestAdjuster(cap: 16877.0),
                MinimumDenialManifestAdjuster(minimum: 1.6),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 63741.9
        )
    }
}
