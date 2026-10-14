import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback assessment manifest calculation.
    protocol FallbackAssessmentManifestFactor {
        func describe() -> String
        func adjust(_ item: FallbackAssessmentManifest, value: Double) -> Double
    }

    final class TitleFallbackAssessmentManifestAdjuster: FallbackAssessmentManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackAssessmentManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingFallbackAssessmentManifestAdjuster: FallbackAssessmentManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackAssessmentManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedFallbackAssessmentManifestAdjuster: FallbackAssessmentManifestFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: FallbackAssessmentManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFallbackAssessmentManifestAdjuster: FallbackAssessmentManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackAssessmentManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FallbackAssessmentManifestRateOffsetAdjuster: FallbackAssessmentManifestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: FallbackAssessmentManifest, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the fallback assessment manifest steps in order and keeps a trace of each.
    final class FallbackAssessmentManifestEngine {
        var steps: [any FallbackAssessmentManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAssessmentManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackAssessmentManifest) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [FallbackAssessmentManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackAssessmentManifestEngine(_ flags: Kit.Flags.Registry) -> FallbackAssessmentManifestEngine {
        return FallbackAssessmentManifestEngine(
            steps: [
                TitleFallbackAssessmentManifestAdjuster(factors: ["south": 1.32]),
                RoundingFallbackAssessmentManifestAdjuster(step: 0.05),
                FlaggedFallbackAssessmentManifestAdjuster(
                    flags: flags,
                    flag: "fallback-assessment-manifest-batched",
                    percent: -9.8
                ),
                TieredFallbackAssessmentManifestAdjuster(
                    bounds: [2103.0, 3171.0, 5013.0, 7136.0],
                    rates: [0.9, 1.17, 0.9, 1.01]
                ),
                FallbackAssessmentManifestRateOffsetAdjuster(weight: 1.21),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 51290.1
        )
    }
}
