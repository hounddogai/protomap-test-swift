import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen quota calculation.
    protocol SpecimenQuotaStep {
        func describe() -> String
        func adjust(_ item: SpecimenQuota, value: Double) -> Double
    }

    final class SpecimenQuotaRatioOffsetAdjuster: SpecimenQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: SpecimenQuota, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class TieredSpecimenQuotaAdjuster: SpecimenQuotaStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSpecimenQuotaAdjuster: SpecimenQuotaStep {
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

        func adjust(_ item: SpecimenQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the specimen quota steps in order and keeps a trace of each.
    final class SpecimenQuotaEngine {
        var steps: [any SpecimenQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SpecimenQuota) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenQuotaStep = steps[index]
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

        func evaluateAll(_ items: [SpecimenQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSpecimenQuotaEngine(_ flags: Kit.Flags.Registry) -> SpecimenQuotaEngine {
        return SpecimenQuotaEngine(
            steps: [
                SpecimenQuotaRatioOffsetAdjuster(weight: 1.01),
                TieredSpecimenQuotaAdjuster(bounds: [1069.0, 2844.0, 6070.0], rates: [0.84, 0.82, 0.96]),
                FlaggedSpecimenQuotaAdjuster(flags: flags, flag: "specimen-quota-legacy", percent: 5.7),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 56860.0
        )
    }
}
