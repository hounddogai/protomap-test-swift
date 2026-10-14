import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality policy calculation.
    protocol ModalityPolicyModifier {
        func describe() -> String
        func adjust(_ item: ModalityPolicy, value: Double) -> Double
    }

    final class FlaggedModalityPolicyAdjuster: ModalityPolicyModifier {
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

        func adjust(_ item: ModalityPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumModalityPolicyAdjuster: ModalityPolicyModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredModalityPolicyAdjuster: ModalityPolicyModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ModalityPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ModalityPolicyBudgetOffsetAdjuster: ModalityPolicyModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: ModalityPolicy, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the modality policy steps in order and keeps a trace of each.
    final class ModalityPolicyEngine {
        var steps: [any ModalityPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ModalityPolicy) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [ModalityPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultModalityPolicyEngine(_ flags: Kit.Flags.Registry) -> ModalityPolicyEngine {
        return ModalityPolicyEngine(
            steps: [
                FlaggedModalityPolicyAdjuster(flags: flags, flag: "modality-policy-lenient", percent: -9.9),
                MinimumModalityPolicyAdjuster(minimum: 41.2),
                TieredModalityPolicyAdjuster(bounds: [2182.0, 6301.0, 7779.0], rates: [0.99, 1.12, 0.87]),
                ModalityPolicyBudgetOffsetAdjuster(weight: 1.9),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 15833.7
        )
    }
}
