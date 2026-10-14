import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the fallback worklist group calculation.
    protocol FallbackWorklistGroupStep {
        func describe() -> String
        func adjust(_ item: FallbackWorklistGroup, value: Double) -> Double
    }

    final class FallbackWorklistGroupMaximumOffsetAdjuster: FallbackWorklistGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: FallbackWorklistGroup, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class TieredFallbackWorklistGroupAdjuster: FallbackWorklistGroupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackWorklistGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapFallbackWorklistGroupAdjuster: FallbackWorklistGroupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackWorklistGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumFallbackWorklistGroupAdjuster: FallbackWorklistGroupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackWorklistGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedFallbackWorklistGroupAdjuster: FallbackWorklistGroupStep {
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

        func adjust(_ item: FallbackWorklistGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback worklist group steps in order and keeps a trace of each.
    final class FallbackWorklistGroupEngine {
        var steps: [any FallbackWorklistGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackWorklistGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackWorklistGroup) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [FallbackWorklistGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackWorklistGroupEngine(_ flags: Kit.Flags.Registry) -> FallbackWorklistGroupEngine {
        return FallbackWorklistGroupEngine(
            steps: [
                FallbackWorklistGroupMaximumOffsetAdjuster(weight: 1.3),
                TieredFallbackWorklistGroupAdjuster(bounds: [2125.0, 4078.0], rates: [0.91, 0.94]),
                CapFallbackWorklistGroupAdjuster(cap: 16889.0),
                MinimumFallbackWorklistGroupAdjuster(minimum: 14.8),
                FlaggedFallbackWorklistGroupAdjuster(
                    flags: flags,
                    flag: "fallback-worklist-group-lenient",
                    percent: -9.7
                ),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 35272.0
        )
    }
}
