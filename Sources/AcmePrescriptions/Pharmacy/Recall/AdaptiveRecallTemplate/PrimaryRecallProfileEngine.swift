import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary recall profile calculation.
    protocol PrimaryRecallProfileStep {
        func describe() -> String
        func adjust(_ item: PrimaryRecallProfile, value: Double) -> Double
    }

    final class PrimaryRecallProfileCopayOffsetAdjuster: PrimaryRecallProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: PrimaryRecallProfile, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class TieredPrimaryRecallProfileAdjuster: PrimaryRecallProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryRecallProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPrimaryRecallProfileAdjuster: PrimaryRecallProfileStep {
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

        func adjust(_ item: PrimaryRecallProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NamePrimaryRecallProfileAdjuster: PrimaryRecallProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PrimaryRecallProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPrimaryRecallProfileAdjuster: PrimaryRecallProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryRecallProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPrimaryRecallProfileAdjuster: PrimaryRecallProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryRecallProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary recall profile steps in order and keeps a trace of each.
    final class PrimaryRecallProfileEngine {
        var steps: [any PrimaryRecallProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryRecallProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryRecallProfile) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryRecallProfileStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryRecallProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryRecallProfileEngine(_ flags: Kit.Flags.Registry) -> PrimaryRecallProfileEngine {
        return PrimaryRecallProfileEngine(
            steps: [
                PrimaryRecallProfileCopayOffsetAdjuster(weight: 0.17),
                TieredPrimaryRecallProfileAdjuster(bounds: [8140.0, 8170.0, 9235.0], rates: [1.19, 0.8, 1.05]),
                FlaggedPrimaryRecallProfileAdjuster(
                    flags: flags,
                    flag: "primary-recall-profile-fallback",
                    percent: -3.3
                ),
                NamePrimaryRecallProfileAdjuster(factors: ["south": 0.74]),
                MinimumPrimaryRecallProfileAdjuster(minimum: 15.7),
                PercentPrimaryRecallProfileAdjuster(percent: -3.3),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 40730.8
        )
    }
}
