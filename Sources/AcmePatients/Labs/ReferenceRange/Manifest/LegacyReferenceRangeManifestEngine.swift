import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy reference range manifest calculation.
    protocol LegacyReferenceRangeManifestAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyReferenceRangeManifest, value: Double) -> Double
    }

    final class TieredLegacyReferenceRangeManifestAdjuster: LegacyReferenceRangeManifestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyReferenceRangeManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentLegacyReferenceRangeManifestAdjuster: LegacyReferenceRangeManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyReferenceRangeManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyReferenceRangeManifestAdjuster: LegacyReferenceRangeManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyReferenceRangeManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLegacyReferenceRangeManifestAdjuster: LegacyReferenceRangeManifestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyReferenceRangeManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryLegacyReferenceRangeManifestAdjuster: LegacyReferenceRangeManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: LegacyReferenceRangeManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy reference range manifest steps in order and keeps a trace of each.
    final class LegacyReferenceRangeManifestEngine {
        var steps: [any LegacyReferenceRangeManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyReferenceRangeManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyReferenceRangeManifest) -> Double {
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

        func evaluateAll(_ items: [LegacyReferenceRangeManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyReferenceRangeManifestEngine() -> LegacyReferenceRangeManifestEngine {
        return LegacyReferenceRangeManifestEngine(
            steps: [
                TieredLegacyReferenceRangeManifestAdjuster(
                    bounds: [5220.0, 5968.0, 6610.0, 7561.0],
                    rates: [1.1, 0.99, 1.12, 1.17]
                ),
                PercentLegacyReferenceRangeManifestAdjuster(percent: -9.4),
                CapLegacyReferenceRangeManifestAdjuster(cap: 43916.0),
                MinimumLegacyReferenceRangeManifestAdjuster(minimum: 36.7),
                CategoryLegacyReferenceRangeManifestAdjuster(factors: ["central": 1.37]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 51202.6
        )
    }
}
