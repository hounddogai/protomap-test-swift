import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered assessment manifest calculation.
    protocol TieredAssessmentManifestFactor {
        func describe() -> String
        func adjust(_ item: TieredAssessmentManifest, value: Double) -> Double
    }

    final class MinimumTieredAssessmentManifestAdjuster: TieredAssessmentManifestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredAssessmentManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapTieredAssessmentManifestAdjuster: TieredAssessmentManifestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredAssessmentManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleTieredAssessmentManifestAdjuster: TieredAssessmentManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: TieredAssessmentManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the tiered assessment manifest steps in order and keeps a trace of each.
    final class TieredAssessmentManifestEngine {
        var steps: [any TieredAssessmentManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredAssessmentManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredAssessmentManifest) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [TieredAssessmentManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredAssessmentManifestEngine() -> TieredAssessmentManifestEngine {
        return TieredAssessmentManifestEngine(
            steps: [
                MinimumTieredAssessmentManifestAdjuster(minimum: 10.1),
                CapTieredAssessmentManifestAdjuster(cap: 3090.0),
                TitleTieredAssessmentManifestAdjuster(factors: ["retail": 0.9]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 90715.7
        )
    }
}
