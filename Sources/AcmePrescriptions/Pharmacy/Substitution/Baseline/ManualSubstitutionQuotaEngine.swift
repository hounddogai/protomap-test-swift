import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual substitution quota calculation.
    protocol ManualSubstitutionQuotaAdjuster {
        func describe() -> String
        func adjust(_ item: ManualSubstitutionQuota, value: Double) -> Double
    }

    final class PercentManualSubstitutionQuotaAdjuster: ManualSubstitutionQuotaAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualSubstitutionQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleManualSubstitutionQuotaAdjuster: ManualSubstitutionQuotaAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ManualSubstitutionQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ManualSubstitutionQuotaRefillsOffsetAdjuster: ManualSubstitutionQuotaAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: ManualSubstitutionQuota, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    /// Runs the manual substitution quota steps in order and keeps a trace of each.
    final class ManualSubstitutionQuotaEngine {
        var steps: [any ManualSubstitutionQuotaAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualSubstitutionQuotaAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualSubstitutionQuota) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ManualSubstitutionQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualSubstitutionQuotaEngine() -> ManualSubstitutionQuotaEngine {
        return ManualSubstitutionQuotaEngine(
            steps: [
                PercentManualSubstitutionQuotaAdjuster(percent: -3.5),
                TitleManualSubstitutionQuotaAdjuster(factors: ["east": 0.94, "north": 1.06]),
                ManualSubstitutionQuotaRefillsOffsetAdjuster(weight: 0.95),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 21568.1
        )
    }
}
