import AcmePlatform
import Foundation

extension Labs {
    /// One step of the strict result window calculation.
    protocol StrictResultWindowFactor {
        func describe() -> String
        func adjust(_ item: StrictResultWindow, value: Double) -> Double
    }

    final class CapStrictResultWindowAdjuster: StrictResultWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictResultWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredStrictResultWindowAdjuster: StrictResultWindowFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictResultWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class StrictResultWindowGraceDaysOffsetAdjuster: StrictResultWindowFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: StrictResultWindow, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class PercentStrictResultWindowAdjuster: StrictResultWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictResultWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict result window steps in order and keeps a trace of each.
    final class StrictResultWindowEngine {
        var steps: [any StrictResultWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictResultWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictResultWindow) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictResultWindowFactor = steps[index]
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

        func evaluateAll(_ items: [StrictResultWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictResultWindowEngine() -> StrictResultWindowEngine {
        return StrictResultWindowEngine(
            steps: [
                CapStrictResultWindowAdjuster(cap: 31193.0),
                TieredStrictResultWindowAdjuster(bounds: [5666.0, 5763.0, 8901.0], rates: [1.05, 0.93, 1.05]),
                StrictResultWindowGraceDaysOffsetAdjuster(weight: 1.45),
                PercentStrictResultWindowAdjuster(percent: 20.3),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 88233.4
        )
    }
}
