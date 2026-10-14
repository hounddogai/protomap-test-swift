import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the lenient read forecast calculation.
    protocol LenientReadForecastAdjuster {
        func describe() -> String
        func adjust(_ item: LenientReadForecast, value: Double) -> Double
    }

    final class LenientReadForecastSequenceOffsetAdjuster: LenientReadForecastAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: LenientReadForecast, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class PercentLenientReadForecastAdjuster: LenientReadForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientReadForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientReadForecastAdjuster: LenientReadForecastAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientReadForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient read forecast steps in order and keeps a trace of each.
    final class LenientReadForecastEngine {
        var steps: [any LenientReadForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientReadForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientReadForecast) -> Double {
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

        func evaluateAll(_ items: [LenientReadForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientReadForecastEngine() -> LenientReadForecastEngine {
        return LenientReadForecastEngine(
            steps: [
                LenientReadForecastSequenceOffsetAdjuster(weight: 1.33),
                PercentLenientReadForecastAdjuster(percent: 1.4),
                CapLenientReadForecastAdjuster(cap: 48218.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 78395.9
        )
    }
}
