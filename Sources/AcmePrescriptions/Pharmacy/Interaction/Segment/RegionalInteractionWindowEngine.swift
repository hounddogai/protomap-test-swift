import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the regional interaction window calculation.
    protocol RegionalInteractionWindowAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalInteractionWindow, value: Double) -> Double
    }

    final class RegionalInteractionWindowAcuityOffsetAdjuster: RegionalInteractionWindowAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: RegionalInteractionWindow, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class TitleRegionalInteractionWindowAdjuster: RegionalInteractionWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalInteractionWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRegionalInteractionWindowAdjuster: RegionalInteractionWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalInteractionWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRegionalInteractionWindowAdjuster: RegionalInteractionWindowAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalInteractionWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRegionalInteractionWindowAdjuster: RegionalInteractionWindowAdjuster {
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

        func adjust(_ item: RegionalInteractionWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional interaction window steps in order and keeps a trace of each.
    final class RegionalInteractionWindowEngine {
        var steps: [any RegionalInteractionWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalInteractionWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalInteractionWindow) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalInteractionWindowAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalInteractionWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalInteractionWindowEngine(_ flags: Kit.Flags.Registry) -> RegionalInteractionWindowEngine {
        return RegionalInteractionWindowEngine(
            steps: [
                RegionalInteractionWindowAcuityOffsetAdjuster(weight: 1.43),
                TitleRegionalInteractionWindowAdjuster(factors: ["retail": 1.07]),
                PercentRegionalInteractionWindowAdjuster(percent: -14.9),
                CapRegionalInteractionWindowAdjuster(cap: 6422.0),
                FlaggedRegionalInteractionWindowAdjuster(
                    flags: flags,
                    flag: "regional-interaction-window-legacy",
                    percent: -4.9
                ),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 82390.7
        )
    }
}
