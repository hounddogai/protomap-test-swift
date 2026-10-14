import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback reference range variance calculation.
    protocol FallbackReferenceRangeVarianceFactor {
        func describe() -> String
        func adjust(_ item: FallbackReferenceRangeVariance, value: Double) -> Double
    }

    final class FlaggedFallbackReferenceRangeVarianceAdjuster: FallbackReferenceRangeVarianceFactor {
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

        func adjust(_ item: FallbackReferenceRangeVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionFallbackReferenceRangeVarianceAdjuster: FallbackReferenceRangeVarianceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: FallbackReferenceRangeVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackReferenceRangeVarianceAdjuster: FallbackReferenceRangeVarianceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackReferenceRangeVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback reference range variance steps in order and keeps a trace of each.
    final class FallbackReferenceRangeVarianceEngine {
        var steps: [any FallbackReferenceRangeVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackReferenceRangeVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackReferenceRangeVariance) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [FallbackReferenceRangeVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackReferenceRangeVarianceEngine(_ flags: Kit.Flags.Registry) -> FallbackReferenceRangeVarianceEngine {
        return FallbackReferenceRangeVarianceEngine(
            steps: [
                FlaggedFallbackReferenceRangeVarianceAdjuster(
                    flags: flags,
                    flag: "fallback-reference-range-variance-tiered",
                    percent: 8.3
                ),
                RegionFallbackReferenceRangeVarianceAdjuster(factors: ["online": 1.15, "south": 1.16, "north": 1.18]),
                MinimumFallbackReferenceRangeVarianceAdjuster(minimum: 17.2),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 82863.1
        )
    }
}
