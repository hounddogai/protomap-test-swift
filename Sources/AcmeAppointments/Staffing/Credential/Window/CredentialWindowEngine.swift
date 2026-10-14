import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential window calculation.
    protocol CredentialWindowModifier {
        func describe() -> String
        func adjust(_ item: CredentialWindow, value: Double) -> Double
    }

    final class TieredCredentialWindowAdjuster: CredentialWindowModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CredentialWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCredentialWindowAdjuster: CredentialWindowModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCredentialWindowAdjuster: CredentialWindowModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentCredentialWindowAdjuster: CredentialWindowModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: CredentialWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CredentialWindowDiscountOffsetAdjuster: CredentialWindowModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: CredentialWindow, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class RoundingCredentialWindowAdjuster: CredentialWindowModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the credential window steps in order and keeps a trace of each.
    final class CredentialWindowEngine {
        var steps: [any CredentialWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CredentialWindow) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [CredentialWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCredentialWindowEngine() -> CredentialWindowEngine {
        return CredentialWindowEngine(
            steps: [
                TieredCredentialWindowAdjuster(bounds: [620.0, 7979.0], rates: [0.99, 0.99]),
                PercentCredentialWindowAdjuster(percent: 6.6),
                MinimumCredentialWindowAdjuster(minimum: 10.2),
                SegmentCredentialWindowAdjuster(factors: ["central": 1.12]),
                CredentialWindowDiscountOffsetAdjuster(weight: 1.09),
                RoundingCredentialWindowAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 99367.6
        )
    }
}
