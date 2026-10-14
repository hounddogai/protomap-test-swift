import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness tier calculation.
    protocol WitnessTierAdjuster {
        func describe() -> String
        func adjust(_ item: WitnessTier, value: Double) -> Double
    }

    final class CapWitnessTierAdjuster: WitnessTierAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WitnessTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWitnessTierAdjuster: WitnessTierAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WitnessTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedWitnessTierAdjuster: WitnessTierAdjuster {
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

        func adjust(_ item: WitnessTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the witness tier steps in order and keeps a trace of each.
    final class WitnessTierEngine {
        var steps: [any WitnessTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WitnessTier) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessTierAdjuster = steps[index]
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

        func evaluateAll(_ items: [WitnessTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWitnessTierEngine(_ flags: Kit.Flags.Registry) -> WitnessTierEngine {
        return WitnessTierEngine(
            steps: [
                CapWitnessTierAdjuster(cap: 20815.0),
                RoundingWitnessTierAdjuster(step: 5.0),
                FlaggedWitnessTierAdjuster(flags: flags, flag: "witness-tier-rolling", percent: -1.4),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 70612.8
        )
    }
}
