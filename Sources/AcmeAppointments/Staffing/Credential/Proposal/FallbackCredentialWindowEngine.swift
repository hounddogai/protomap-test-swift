import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback credential window calculation.
    protocol FallbackCredentialWindowFactor {
        func describe() -> String
        func adjust(_ item: FallbackCredentialWindow, value: Double) -> Double
    }

    final class FlaggedFallbackCredentialWindowAdjuster: FallbackCredentialWindowFactor {
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

        func adjust(_ item: FallbackCredentialWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackCredentialWindowStartsAtOffsetAdjuster: FallbackCredentialWindowFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: FallbackCredentialWindow, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class MinimumFallbackCredentialWindowAdjuster: FallbackCredentialWindowFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCredentialWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapFallbackCredentialWindowAdjuster: FallbackCredentialWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackCredentialWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback credential window steps in order and keeps a trace of each.
    final class FallbackCredentialWindowEngine {
        var steps: [any FallbackCredentialWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCredentialWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackCredentialWindow) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackCredentialWindowFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackCredentialWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackCredentialWindowEngine(_ flags: Kit.Flags.Registry) -> FallbackCredentialWindowEngine {
        return FallbackCredentialWindowEngine(
            steps: [
                FlaggedFallbackCredentialWindowAdjuster(
                    flags: flags,
                    flag: "fallback-credential-window-capped",
                    percent: 1.6
                ),
                FallbackCredentialWindowStartsAtOffsetAdjuster(weight: 1.39),
                MinimumFallbackCredentialWindowAdjuster(minimum: 23.3),
                CapFallbackCredentialWindowAdjuster(cap: 24418.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 70070.0
        )
    }
}
