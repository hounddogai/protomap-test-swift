import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense bundle calculation.
    protocol DispenseBundleFactor {
        func describe() -> String
        func adjust(_ item: DispenseBundle, value: Double) -> Double
    }

    final class MinimumDispenseBundleAdjuster: DispenseBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDispenseBundleAdjuster: DispenseBundleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispenseBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDispenseBundleAdjuster: DispenseBundleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the dispense bundle steps in order and keeps a trace of each.
    final class DispenseBundleEngine {
        var steps: [any DispenseBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DispenseBundle) -> Double {
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

        func evaluateAll(_ items: [DispenseBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDispenseBundleEngine() -> DispenseBundleEngine {
        return DispenseBundleEngine(
            steps: [
                MinimumDispenseBundleAdjuster(minimum: 36.8),
                TieredDispenseBundleAdjuster(bounds: [265.0, 1742.0, 6097.0, 9632.0], rates: [0.86, 1.0, 0.81, 1.05]),
                PercentDispenseBundleAdjuster(percent: -23.8),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 49982.8
        )
    }
}
