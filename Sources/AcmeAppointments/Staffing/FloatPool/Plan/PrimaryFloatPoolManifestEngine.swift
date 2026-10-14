import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary float pool manifest calculation.
    protocol PrimaryFloatPoolManifestStep {
        func describe() -> String
        func adjust(_ item: PrimaryFloatPoolManifest, value: Double) -> Double
    }

    final class FlaggedPrimaryFloatPoolManifestAdjuster: PrimaryFloatPoolManifestStep {
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

        func adjust(_ item: PrimaryFloatPoolManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPrimaryFloatPoolManifestAdjuster: PrimaryFloatPoolManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryFloatPoolManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryFloatPoolManifestAdjuster: PrimaryFloatPoolManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryFloatPoolManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrimaryFloatPoolManifestAdjuster: PrimaryFloatPoolManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryFloatPoolManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPrimaryFloatPoolManifestAdjuster: PrimaryFloatPoolManifestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryFloatPoolManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary float pool manifest steps in order and keeps a trace of each.
    final class PrimaryFloatPoolManifestEngine {
        var steps: [any PrimaryFloatPoolManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryFloatPoolManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryFloatPoolManifest) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryFloatPoolManifestStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [PrimaryFloatPoolManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryFloatPoolManifestEngine(_ flags: Kit.Flags.Registry) -> PrimaryFloatPoolManifestEngine {
        return PrimaryFloatPoolManifestEngine(
            steps: [
                FlaggedPrimaryFloatPoolManifestAdjuster(
                    flags: flags,
                    flag: "primary-float-pool-manifest-manual",
                    percent: -6.4
                ),
                PercentPrimaryFloatPoolManifestAdjuster(percent: -12.1),
                TieredPrimaryFloatPoolManifestAdjuster(bounds: [5099.0, 6727.0], rates: [0.96, 1.09]),
                RoundingPrimaryFloatPoolManifestAdjuster(step: 0.1),
                MinimumPrimaryFloatPoolManifestAdjuster(minimum: 18.3),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 5943.3
        )
    }
}
