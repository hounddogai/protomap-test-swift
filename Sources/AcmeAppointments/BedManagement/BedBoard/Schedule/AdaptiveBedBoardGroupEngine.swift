import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the adaptive bed board group calculation.
    protocol AdaptiveBedBoardGroupAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveBedBoardGroup, value: Double) -> Double
    }

    final class RoundingAdaptiveBedBoardGroupAdjuster: AdaptiveBedBoardGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveBedBoardGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAdaptiveBedBoardGroupAdjuster: AdaptiveBedBoardGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveBedBoardGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAdaptiveBedBoardGroupAdjuster: AdaptiveBedBoardGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveBedBoardGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveBedBoardGroupAdjuster: AdaptiveBedBoardGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveBedBoardGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumAdaptiveBedBoardGroupAdjuster: AdaptiveBedBoardGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveBedBoardGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAdaptiveBedBoardGroupAdjuster: AdaptiveBedBoardGroupAdjuster {
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

        func adjust(_ item: AdaptiveBedBoardGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive bed board group steps in order and keeps a trace of each.
    final class AdaptiveBedBoardGroupEngine {
        var steps: [any AdaptiveBedBoardGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveBedBoardGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveBedBoardGroup) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [AdaptiveBedBoardGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveBedBoardGroupEngine(_ flags: Kit.Flags.Registry) -> AdaptiveBedBoardGroupEngine {
        return AdaptiveBedBoardGroupEngine(
            steps: [
                RoundingAdaptiveBedBoardGroupAdjuster(step: 0.5),
                TieredAdaptiveBedBoardGroupAdjuster(bounds: [1795.0, 4052.0, 4300.0], rates: [1.15, 0.8, 1.1]),
                PercentAdaptiveBedBoardGroupAdjuster(percent: -2.3),
                CapAdaptiveBedBoardGroupAdjuster(cap: 44098.0),
                MinimumAdaptiveBedBoardGroupAdjuster(minimum: 14.7),
                FlaggedAdaptiveBedBoardGroupAdjuster(
                    flags: flags,
                    flag: "adaptive-bed-board-group-lenient",
                    percent: -8.7
                ),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 27097.3
        )
    }
}
