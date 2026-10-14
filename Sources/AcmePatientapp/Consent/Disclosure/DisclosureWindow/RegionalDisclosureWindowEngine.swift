import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional disclosure window calculation.
    protocol RegionalDisclosureWindowAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalDisclosureWindow, value: Double) -> Double
    }

    final class PercentRegionalDisclosureWindowAdjuster: RegionalDisclosureWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalDisclosureWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRegionalDisclosureWindowAdjuster: RegionalDisclosureWindowAdjuster {
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

        func adjust(_ item: RegionalDisclosureWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalDisclosureWindowAdjuster: RegionalDisclosureWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalDisclosureWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelRegionalDisclosureWindowAdjuster: RegionalDisclosureWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RegionalDisclosureWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRegionalDisclosureWindowAdjuster: RegionalDisclosureWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalDisclosureWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional disclosure window steps in order and keeps a trace of each.
    final class RegionalDisclosureWindowEngine {
        var steps: [any RegionalDisclosureWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalDisclosureWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalDisclosureWindow) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [RegionalDisclosureWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalDisclosureWindowEngine(_ flags: Kit.Flags.Registry) -> RegionalDisclosureWindowEngine {
        return RegionalDisclosureWindowEngine(
            steps: [
                PercentRegionalDisclosureWindowAdjuster(percent: 4.1),
                FlaggedRegionalDisclosureWindowAdjuster(
                    flags: flags,
                    flag: "regional-disclosure-window-regional",
                    percent: 5.2
                ),
                RoundingRegionalDisclosureWindowAdjuster(step: 0.5),
                ChannelRegionalDisclosureWindowAdjuster(factors: ["east": 0.85, "north": 1.12, "south": 0.82]),
                MinimumRegionalDisclosureWindowAdjuster(minimum: 26.3),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 93862.1
        )
    }
}
