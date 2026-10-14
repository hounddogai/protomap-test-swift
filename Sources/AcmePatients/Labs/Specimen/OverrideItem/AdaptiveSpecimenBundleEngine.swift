import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive specimen bundle calculation.
    protocol AdaptiveSpecimenBundleFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveSpecimenBundle, value: Double) -> Double
    }

    final class PercentAdaptiveSpecimenBundleAdjuster: AdaptiveSpecimenBundleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveSpecimenBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAdaptiveSpecimenBundleAdjuster: AdaptiveSpecimenBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveSpecimenBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedAdaptiveSpecimenBundleAdjuster: AdaptiveSpecimenBundleFactor {
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

        func adjust(_ item: AdaptiveSpecimenBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitAdaptiveSpecimenBundleAdjuster: AdaptiveSpecimenBundleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: AdaptiveSpecimenBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the adaptive specimen bundle steps in order and keeps a trace of each.
    final class AdaptiveSpecimenBundleEngine {
        var steps: [any AdaptiveSpecimenBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveSpecimenBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveSpecimenBundle) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveSpecimenBundleFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptiveSpecimenBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveSpecimenBundleEngine(_ flags: Kit.Flags.Registry) -> AdaptiveSpecimenBundleEngine {
        return AdaptiveSpecimenBundleEngine(
            steps: [
                PercentAdaptiveSpecimenBundleAdjuster(percent: 4.3),
                RoundingAdaptiveSpecimenBundleAdjuster(step: 1.0),
                FlaggedAdaptiveSpecimenBundleAdjuster(
                    flags: flags,
                    flag: "adaptive-specimen-bundle-strict",
                    percent: -0.2
                ),
                UnitAdaptiveSpecimenBundleAdjuster(factors: ["east": 1.19, "west": 0.72]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 18189.8
        )
    }
}
