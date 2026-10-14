import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the strict assessment bundle calculation.
    protocol StrictAssessmentBundleAdjuster {
        func describe() -> String
        func adjust(_ item: StrictAssessmentBundle, value: Double) -> Double
    }

    final class ChannelStrictAssessmentBundleAdjuster: StrictAssessmentBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: StrictAssessmentBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class StrictAssessmentBundleMinimumOffsetAdjuster: StrictAssessmentBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: StrictAssessmentBundle, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class RoundingStrictAssessmentBundleAdjuster: StrictAssessmentBundleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictAssessmentBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStrictAssessmentBundleAdjuster: StrictAssessmentBundleAdjuster {
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

        func adjust(_ item: StrictAssessmentBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictAssessmentBundleAdjuster: StrictAssessmentBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictAssessmentBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict assessment bundle steps in order and keeps a trace of each.
    final class StrictAssessmentBundleEngine {
        var steps: [any StrictAssessmentBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictAssessmentBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictAssessmentBundle) -> Double {
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

        func evaluateAll(_ items: [StrictAssessmentBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictAssessmentBundleEngine(_ flags: Kit.Flags.Registry) -> StrictAssessmentBundleEngine {
        return StrictAssessmentBundleEngine(
            steps: [
                ChannelStrictAssessmentBundleAdjuster(factors: ["online": 1.33, "west": 1.27]),
                StrictAssessmentBundleMinimumOffsetAdjuster(weight: 0.88),
                RoundingStrictAssessmentBundleAdjuster(step: 0.5),
                FlaggedStrictAssessmentBundleAdjuster(
                    flags: flags,
                    flag: "strict-assessment-bundle-seasonal",
                    percent: 8.2
                ),
                TieredStrictAssessmentBundleAdjuster(bounds: [424.0, 1338.0], rates: [0.82, 1.03]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 15195.1
        )
    }
}
