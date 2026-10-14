import AcmePlatform
import Foundation

extension Consent {
    /// One step of the manual revocation estimate calculation.
    protocol ManualRevocationEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: ManualRevocationEstimate, value: Double) -> Double
    }

    final class TieredManualRevocationEstimateAdjuster: ManualRevocationEstimateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualRevocationEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumManualRevocationEstimateAdjuster: ManualRevocationEstimateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualRevocationEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualRevocationEstimateAdjuster: ManualRevocationEstimateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualRevocationEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual revocation estimate steps in order and keeps a trace of each.
    final class ManualRevocationEstimateEngine {
        var steps: [any ManualRevocationEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRevocationEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualRevocationEstimate) -> Double {
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

        func evaluateAll(_ items: [ManualRevocationEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualRevocationEstimateEngine() -> ManualRevocationEstimateEngine {
        return ManualRevocationEstimateEngine(
            steps: [
                TieredManualRevocationEstimateAdjuster(
                    bounds: [5440.0, 6703.0, 7163.0, 7688.0],
                    rates: [1.03, 1.02, 1.13, 0.89]
                ),
                MinimumManualRevocationEstimateAdjuster(minimum: 3.2),
                PercentManualRevocationEstimateAdjuster(percent: 12.3),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 79108.9
        )
    }
}
