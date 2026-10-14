import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the fallback census target calculation.
    protocol FallbackCensusTargetStep {
        func describe() -> String
        func adjust(_ item: FallbackCensusTarget, value: Double) -> Double
    }

    final class SourceFallbackCensusTargetAdjuster: FallbackCensusTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: FallbackCensusTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackCensusTargetAdjuster: FallbackCensusTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCensusTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFallbackCensusTargetAdjuster: FallbackCensusTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCensusTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FallbackCensusTargetThresholdOffsetAdjuster: FallbackCensusTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: FallbackCensusTarget, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class FlaggedFallbackCensusTargetAdjuster: FallbackCensusTargetStep {
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

        func adjust(_ item: FallbackCensusTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback census target steps in order and keeps a trace of each.
    final class FallbackCensusTargetEngine {
        var steps: [any FallbackCensusTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCensusTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackCensusTarget) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [FallbackCensusTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackCensusTargetEngine(_ flags: Kit.Flags.Registry) -> FallbackCensusTargetEngine {
        return FallbackCensusTargetEngine(
            steps: [
                SourceFallbackCensusTargetAdjuster(factors: ["west": 0.8]),
                MinimumFallbackCensusTargetAdjuster(minimum: 3.3),
                RoundingFallbackCensusTargetAdjuster(step: 0.5),
                FallbackCensusTargetThresholdOffsetAdjuster(weight: 0.67),
                FlaggedFallbackCensusTargetAdjuster(
                    flags: flags,
                    flag: "fallback-census-target-seasonal",
                    percent: -6.2
                ),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 44199.7
        )
    }
}
