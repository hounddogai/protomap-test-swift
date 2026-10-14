import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the fallback care protocol window calculation.
    protocol FallbackCareProtocolWindowAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackCareProtocolWindow, value: Double) -> Double
    }

    final class TitleFallbackCareProtocolWindowAdjuster: FallbackCareProtocolWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackCareProtocolWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingFallbackCareProtocolWindowAdjuster: FallbackCareProtocolWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCareProtocolWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFallbackCareProtocolWindowAdjuster: FallbackCareProtocolWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackCareProtocolWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackCareProtocolWindowCreatedAtOffsetAdjuster: FallbackCareProtocolWindowAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: FallbackCareProtocolWindow, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class MinimumFallbackCareProtocolWindowAdjuster: FallbackCareProtocolWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCareProtocolWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedFallbackCareProtocolWindowAdjuster: FallbackCareProtocolWindowAdjuster {
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

        func adjust(_ item: FallbackCareProtocolWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback care protocol window steps in order and keeps a trace of each.
    final class FallbackCareProtocolWindowEngine {
        var steps: [any FallbackCareProtocolWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCareProtocolWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackCareProtocolWindow) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [FallbackCareProtocolWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackCareProtocolWindowEngine(_ flags: Kit.Flags.Registry) -> FallbackCareProtocolWindowEngine {
        return FallbackCareProtocolWindowEngine(
            steps: [
                TitleFallbackCareProtocolWindowAdjuster(factors: ["retail": 0.75, "east": 1.36]),
                RoundingFallbackCareProtocolWindowAdjuster(step: 0.05),
                PercentFallbackCareProtocolWindowAdjuster(percent: -13.8),
                FallbackCareProtocolWindowCreatedAtOffsetAdjuster(weight: 1.67),
                MinimumFallbackCareProtocolWindowAdjuster(minimum: 21.7),
                FlaggedFallbackCareProtocolWindowAdjuster(
                    flags: flags,
                    flag: "fallback-care-protocol-window-legacy",
                    percent: 2.4
                ),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 36082.6
        )
    }
}
