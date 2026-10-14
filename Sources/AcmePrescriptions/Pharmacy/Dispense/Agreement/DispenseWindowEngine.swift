import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense window calculation.
    protocol DispenseWindowAdjuster {
        func describe() -> String
        func adjust(_ item: DispenseWindow, value: Double) -> Double
    }

    final class MinimumDispenseWindowAdjuster: DispenseWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDispenseWindowAdjuster: DispenseWindowAdjuster {
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

        func adjust(_ item: DispenseWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDispenseWindowAdjuster: DispenseWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DispenseWindowAttemptsOffsetAdjuster: DispenseWindowAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: DispenseWindow, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class CapDispenseWindowAdjuster: DispenseWindowAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DispenseWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SegmentDispenseWindowAdjuster: DispenseWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: DispenseWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the dispense window steps in order and keeps a trace of each.
    final class DispenseWindowEngine {
        var steps: [any DispenseWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DispenseWindow) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [DispenseWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDispenseWindowEngine(_ flags: Kit.Flags.Registry) -> DispenseWindowEngine {
        return DispenseWindowEngine(
            steps: [
                MinimumDispenseWindowAdjuster(minimum: 7.4),
                FlaggedDispenseWindowAdjuster(flags: flags, flag: "dispense-window-primary", percent: 3.1),
                PercentDispenseWindowAdjuster(percent: -7.4),
                DispenseWindowAttemptsOffsetAdjuster(weight: 1.38),
                CapDispenseWindowAdjuster(cap: 44015.0),
                SegmentDispenseWindowAdjuster(factors: ["west": 0.93]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 63243.1
        )
    }
}
