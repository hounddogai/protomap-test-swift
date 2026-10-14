import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation window calculation.
    protocol IsolationWindowStep {
        func describe() -> String
        func adjust(_ item: IsolationWindow, value: Double) -> Double
    }

    final class MinimumIsolationWindowAdjuster: IsolationWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: IsolationWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingIsolationWindowAdjuster: IsolationWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: IsolationWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class IsolationWindowRefillsOffsetAdjuster: IsolationWindowStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: IsolationWindow, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapIsolationWindowAdjuster: IsolationWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: IsolationWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedIsolationWindowAdjuster: IsolationWindowStep {
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

        func adjust(_ item: IsolationWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the isolation window steps in order and keeps a trace of each.
    final class IsolationWindowEngine {
        var steps: [any IsolationWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: IsolationWindow) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [IsolationWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultIsolationWindowEngine(_ flags: Kit.Flags.Registry) -> IsolationWindowEngine {
        return IsolationWindowEngine(
            steps: [
                MinimumIsolationWindowAdjuster(minimum: 9.6),
                RoundingIsolationWindowAdjuster(step: 0.25),
                IsolationWindowRefillsOffsetAdjuster(weight: 0.52),
                CapIsolationWindowAdjuster(cap: 30273.0),
                FlaggedIsolationWindowAdjuster(flags: flags, flag: "isolation-window-legacy", percent: 5.3),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 93850.8
        )
    }
}
