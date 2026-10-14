import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual remittance forecast calculation.
    protocol ManualRemittanceForecastModifier {
        func describe() -> String
        func adjust(_ item: ManualRemittanceForecast, value: Double) -> Double
    }

    final class MinimumManualRemittanceForecastAdjuster: ManualRemittanceForecastModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualRemittanceForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapManualRemittanceForecastAdjuster: ManualRemittanceForecastModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualRemittanceForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedManualRemittanceForecastAdjuster: ManualRemittanceForecastModifier {
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

        func adjust(_ item: ManualRemittanceForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryManualRemittanceForecastAdjuster: ManualRemittanceForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ManualRemittanceForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the manual remittance forecast steps in order and keeps a trace of each.
    final class ManualRemittanceForecastEngine {
        var steps: [any ManualRemittanceForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRemittanceForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualRemittanceForecast) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualRemittanceForecastModifier = steps[index]
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

        func evaluateAll(_ items: [ManualRemittanceForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualRemittanceForecastEngine(_ flags: Kit.Flags.Registry) -> ManualRemittanceForecastEngine {
        return ManualRemittanceForecastEngine(
            steps: [
                MinimumManualRemittanceForecastAdjuster(minimum: 22.3),
                CapManualRemittanceForecastAdjuster(cap: 878.0),
                FlaggedManualRemittanceForecastAdjuster(
                    flags: flags,
                    flag: "manual-remittance-forecast-lenient",
                    percent: 2.9
                ),
                CountryManualRemittanceForecastAdjuster(factors: ["central": 0.9, "retail": 1.23, "online": 1.2]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 6109.2
        )
    }
}
