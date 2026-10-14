import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession preference calculation.
    protocol AccessionPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: AccessionPreference, value: Double) -> Double
    }

    final class SourceAccessionPreferenceAdjuster: AccessionPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: AccessionPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAccessionPreferenceAdjuster: AccessionPreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAccessionPreferenceAdjuster: AccessionPreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAccessionPreferenceAdjuster: AccessionPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAccessionPreferenceAdjuster: AccessionPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the accession preference steps in order and keeps a trace of each.
    final class AccessionPreferenceEngine {
        var steps: [any AccessionPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AccessionPreference) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [AccessionPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAccessionPreferenceEngine() -> AccessionPreferenceEngine {
        return AccessionPreferenceEngine(
            steps: [
                SourceAccessionPreferenceAdjuster(factors: ["north": 1.05, "south": 1.26]),
                PercentAccessionPreferenceAdjuster(percent: 9.0),
                TieredAccessionPreferenceAdjuster(bounds: [1232.0, 6302.0], rates: [0.81, 1.07]),
                MinimumAccessionPreferenceAdjuster(minimum: 27.9),
                CapAccessionPreferenceAdjuster(cap: 24232.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 74532.4
        )
    }
}
