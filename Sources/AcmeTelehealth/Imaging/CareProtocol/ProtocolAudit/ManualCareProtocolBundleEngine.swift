import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the manual care protocol bundle calculation.
    protocol ManualCareProtocolBundleStep {
        func describe() -> String
        func adjust(_ item: ManualCareProtocolBundle, value: Double) -> Double
    }

    final class MinimumManualCareProtocolBundleAdjuster: ManualCareProtocolBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualCareProtocolBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualCareProtocolBundleAdjuster: ManualCareProtocolBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualCareProtocolBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryManualCareProtocolBundleAdjuster: ManualCareProtocolBundleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ManualCareProtocolBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ManualCareProtocolBundleQuantityOffsetAdjuster: ManualCareProtocolBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ManualCareProtocolBundle, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class TieredManualCareProtocolBundleAdjuster: ManualCareProtocolBundleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualCareProtocolBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual care protocol bundle steps in order and keeps a trace of each.
    final class ManualCareProtocolBundleEngine {
        var steps: [any ManualCareProtocolBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCareProtocolBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualCareProtocolBundle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualCareProtocolBundleStep = steps[index]
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

        func evaluateAll(_ items: [ManualCareProtocolBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualCareProtocolBundleEngine() -> ManualCareProtocolBundleEngine {
        return ManualCareProtocolBundleEngine(
            steps: [
                MinimumManualCareProtocolBundleAdjuster(minimum: 46.3),
                PercentManualCareProtocolBundleAdjuster(percent: 15.6),
                CountryManualCareProtocolBundleAdjuster(factors: ["east": 1.26, "central": 1.0, "retail": 1.14]),
                ManualCareProtocolBundleQuantityOffsetAdjuster(weight: 1.63),
                TieredManualCareProtocolBundleAdjuster(bounds: [7149.0, 7503.0], rates: [1.0, 0.82]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 69330.4
        )
    }
}
