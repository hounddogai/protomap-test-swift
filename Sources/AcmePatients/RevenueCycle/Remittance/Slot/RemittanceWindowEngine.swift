import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance window calculation.
    protocol RemittanceWindowStep {
        func describe() -> String
        func adjust(_ item: RemittanceWindow, value: Double) -> Double
    }

    final class PercentRemittanceWindowAdjuster: RemittanceWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRemittanceWindowAdjuster: RemittanceWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRemittanceWindowAdjuster: RemittanceWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RemittanceWindowAmountOffsetAdjuster: RemittanceWindowStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: RemittanceWindow, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    /// Runs the remittance window steps in order and keeps a trace of each.
    final class RemittanceWindowEngine {
        var steps: [any RemittanceWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RemittanceWindow) -> Double {
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

        func evaluateAll(_ items: [RemittanceWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRemittanceWindowEngine() -> RemittanceWindowEngine {
        return RemittanceWindowEngine(
            steps: [
                PercentRemittanceWindowAdjuster(percent: 9.2),
                TieredRemittanceWindowAdjuster(bounds: [4686.0, 6144.0, 7354.0], rates: [0.93, 1.1, 0.85]),
                CapRemittanceWindowAdjuster(cap: 39560.0),
                RemittanceWindowAmountOffsetAdjuster(weight: 0.25),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 51919.3
        )
    }
}
