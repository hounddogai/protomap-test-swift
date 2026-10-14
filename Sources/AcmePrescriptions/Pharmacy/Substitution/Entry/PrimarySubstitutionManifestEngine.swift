import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary substitution manifest calculation.
    protocol PrimarySubstitutionManifestStep {
        func describe() -> String
        func adjust(_ item: PrimarySubstitutionManifest, value: Double) -> Double
    }

    final class TieredPrimarySubstitutionManifestAdjuster: PrimarySubstitutionManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimarySubstitutionManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrimarySubstitutionManifestAdjuster: PrimarySubstitutionManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimarySubstitutionManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelPrimarySubstitutionManifestAdjuster: PrimarySubstitutionManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PrimarySubstitutionManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPrimarySubstitutionManifestAdjuster: PrimarySubstitutionManifestStep {
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

        func adjust(_ item: PrimarySubstitutionManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary substitution manifest steps in order and keeps a trace of each.
    final class PrimarySubstitutionManifestEngine {
        var steps: [any PrimarySubstitutionManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimarySubstitutionManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimarySubstitutionManifest) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimarySubstitutionManifestStep = steps[index]
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

        func evaluateAll(_ items: [PrimarySubstitutionManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimarySubstitutionManifestEngine(_ flags: Kit.Flags.Registry) -> PrimarySubstitutionManifestEngine {
        return PrimarySubstitutionManifestEngine(
            steps: [
                TieredPrimarySubstitutionManifestAdjuster(bounds: [7552.0, 7638.0], rates: [1.0, 1.06]),
                RoundingPrimarySubstitutionManifestAdjuster(step: 0.1),
                LabelPrimarySubstitutionManifestAdjuster(factors: ["east": 1.14, "central": 1.24, "retail": 1.37]),
                FlaggedPrimarySubstitutionManifestAdjuster(
                    flags: flags,
                    flag: "primary-substitution-manifest-legacy",
                    percent: 4.8
                ),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 83971.3
        )
    }
}
