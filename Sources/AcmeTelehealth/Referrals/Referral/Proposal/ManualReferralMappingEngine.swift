import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual referral mapping calculation.
    protocol ManualReferralMappingAdjuster {
        func describe() -> String
        func adjust(_ item: ManualReferralMapping, value: Double) -> Double
    }

    final class TieredManualReferralMappingAdjuster: ManualReferralMappingAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualReferralMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelManualReferralMappingAdjuster: ManualReferralMappingAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ManualReferralMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumManualReferralMappingAdjuster: ManualReferralMappingAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualReferralMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapManualReferralMappingAdjuster: ManualReferralMappingAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualReferralMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ManualReferralMappingVersionOffsetAdjuster: ManualReferralMappingAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: ManualReferralMapping, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    /// Runs the manual referral mapping steps in order and keeps a trace of each.
    final class ManualReferralMappingEngine {
        var steps: [any ManualReferralMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualReferralMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualReferralMapping) -> Double {
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

        func evaluateAll(_ items: [ManualReferralMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualReferralMappingEngine() -> ManualReferralMappingEngine {
        return ManualReferralMappingEngine(
            steps: [
                TieredManualReferralMappingAdjuster(
                    bounds: [337.0, 3282.0, 4655.0, 9432.0],
                    rates: [0.86, 1.02, 0.98, 1.01]
                ),
                LabelManualReferralMappingAdjuster(factors: ["south": 0.99, "online": 1.27, "central": 1.13]),
                MinimumManualReferralMappingAdjuster(minimum: 2.9),
                CapManualReferralMappingAdjuster(cap: 49963.0),
                ManualReferralMappingVersionOffsetAdjuster(weight: 1.55),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 53759.8
        )
    }
}
