import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap estimate calculation.
    protocol CareGapEstimateModifier {
        func describe() -> String
        func adjust(_ item: CareGapEstimate, value: Double) -> Double
    }

    final class FlaggedCareGapEstimateAdjuster: CareGapEstimateModifier {
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

        func adjust(_ item: CareGapEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCareGapEstimateAdjuster: CareGapEstimateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitCareGapEstimateAdjuster: CareGapEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CareGapEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CareGapEstimateWindowDaysOffsetAdjuster: CareGapEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: CareGapEstimate, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class TieredCareGapEstimateAdjuster: CareGapEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the care gap estimate steps in order and keeps a trace of each.
    final class CareGapEstimateEngine {
        var steps: [any CareGapEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareGapEstimate) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapEstimateModifier = steps[index]
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

        func evaluateAll(_ items: [CareGapEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareGapEstimateEngine(_ flags: Kit.Flags.Registry) -> CareGapEstimateEngine {
        return CareGapEstimateEngine(
            steps: [
                FlaggedCareGapEstimateAdjuster(flags: flags, flag: "care-gap-estimate-default", percent: -5.6),
                MinimumCareGapEstimateAdjuster(minimum: 24.5),
                UnitCareGapEstimateAdjuster(factors: ["south": 1.08, "north": 1.09]),
                CareGapEstimateWindowDaysOffsetAdjuster(weight: 1.1),
                TieredCareGapEstimateAdjuster(bounds: [1915.0, 3881.0, 8193.0], rates: [1.13, 0.94, 0.95]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 27256.5
        )
    }
}
