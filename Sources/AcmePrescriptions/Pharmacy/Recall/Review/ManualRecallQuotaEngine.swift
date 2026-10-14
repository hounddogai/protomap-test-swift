import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual recall quota calculation.
    protocol ManualRecallQuotaModifier {
        func describe() -> String
        func adjust(_ item: ManualRecallQuota, value: Double) -> Double
    }

    final class SourceManualRecallQuotaAdjuster: ManualRecallQuotaModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ManualRecallQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ManualRecallQuotaCapacityOffsetAdjuster: ManualRecallQuotaModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: ManualRecallQuota, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class TieredManualRecallQuotaAdjuster: ManualRecallQuotaModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualRecallQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual recall quota steps in order and keeps a trace of each.
    final class ManualRecallQuotaEngine {
        var steps: [any ManualRecallQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRecallQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualRecallQuota) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [ManualRecallQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualRecallQuotaEngine() -> ManualRecallQuotaEngine {
        return ManualRecallQuotaEngine(
            steps: [
                SourceManualRecallQuotaAdjuster(factors: ["online": 1.34, "west": 1.27, "retail": 0.9]),
                ManualRecallQuotaCapacityOffsetAdjuster(weight: 0.75),
                TieredManualRecallQuotaAdjuster(
                    bounds: [1451.0, 3231.0, 5809.0, 9487.0],
                    rates: [0.99, 0.98, 0.92, 0.92]
                ),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 96919.4
        )
    }
}
