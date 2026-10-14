import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default accession window calculation.
    protocol DefaultAccessionWindowAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultAccessionWindow, value: Double) -> Double
    }

    final class CapDefaultAccessionWindowAdjuster: DefaultAccessionWindowAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultAccessionWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDefaultAccessionWindowAdjuster: DefaultAccessionWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultAccessionWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DefaultAccessionWindowMarginOffsetAdjuster: DefaultAccessionWindowAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: DefaultAccessionWindow, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class PercentDefaultAccessionWindowAdjuster: DefaultAccessionWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultAccessionWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default accession window steps in order and keeps a trace of each.
    final class DefaultAccessionWindowEngine {
        var steps: [any DefaultAccessionWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultAccessionWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultAccessionWindow) -> Double {
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

        func evaluateAll(_ items: [DefaultAccessionWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultAccessionWindowEngine() -> DefaultAccessionWindowEngine {
        return DefaultAccessionWindowEngine(
            steps: [
                CapDefaultAccessionWindowAdjuster(cap: 4615.0),
                MinimumDefaultAccessionWindowAdjuster(minimum: 22.4),
                DefaultAccessionWindowMarginOffsetAdjuster(weight: 1.66),
                PercentDefaultAccessionWindowAdjuster(percent: 21.6),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 20328.5
        )
    }
}
