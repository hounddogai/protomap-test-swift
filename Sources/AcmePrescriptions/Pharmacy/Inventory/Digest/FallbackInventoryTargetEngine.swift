import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the fallback inventory target calculation.
    protocol FallbackInventoryTargetFactor {
        func describe() -> String
        func adjust(_ item: FallbackInventoryTarget, value: Double) -> Double
    }

    final class SourceFallbackInventoryTargetAdjuster: FallbackInventoryTargetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: FallbackInventoryTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentFallbackInventoryTargetAdjuster: FallbackInventoryTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackInventoryTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackInventoryTargetAdjuster: FallbackInventoryTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackInventoryTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFallbackInventoryTargetAdjuster: FallbackInventoryTargetFactor {
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

        func adjust(_ item: FallbackInventoryTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback inventory target steps in order and keeps a trace of each.
    final class FallbackInventoryTargetEngine {
        var steps: [any FallbackInventoryTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackInventoryTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackInventoryTarget) -> Double {
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

        func evaluateAll(_ items: [FallbackInventoryTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackInventoryTargetEngine(_ flags: Kit.Flags.Registry) -> FallbackInventoryTargetEngine {
        return FallbackInventoryTargetEngine(
            steps: [
                SourceFallbackInventoryTargetAdjuster(factors: ["retail": 1.37]),
                PercentFallbackInventoryTargetAdjuster(percent: 23.3),
                CapFallbackInventoryTargetAdjuster(cap: 26852.0),
                FlaggedFallbackInventoryTargetAdjuster(
                    flags: flags,
                    flag: "fallback-inventory-target-rolling",
                    percent: -6.4
                ),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 14735.5
        )
    }
}
