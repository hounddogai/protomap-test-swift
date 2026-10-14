import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read window calculation.
    protocol ReadWindowAdjuster {
        func describe() -> String
        func adjust(_ item: ReadWindow, value: Double) -> Double
    }

    final class MinimumReadWindowAdjuster: ReadWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReadWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentReadWindowAdjuster: ReadWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapReadWindowAdjuster: ReadWindowAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingReadWindowAdjuster: ReadWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the read window steps in order and keeps a trace of each.
    final class ReadWindowEngine {
        var steps: [any ReadWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReadWindow) -> Double {
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

        func evaluateAll(_ items: [ReadWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReadWindowEngine() -> ReadWindowEngine {
        return ReadWindowEngine(
            steps: [
                MinimumReadWindowAdjuster(minimum: 9.7),
                PercentReadWindowAdjuster(percent: -5.2),
                CapReadWindowAdjuster(cap: 19235.0),
                RoundingReadWindowAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 97863.7
        )
    }
}
