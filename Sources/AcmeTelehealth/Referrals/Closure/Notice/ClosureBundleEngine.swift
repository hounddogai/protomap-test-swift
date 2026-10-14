import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure bundle calculation.
    protocol ClosureBundleModifier {
        func describe() -> String
        func adjust(_ item: ClosureBundle, value: Double) -> Double
    }

    final class CapClosureBundleAdjuster: ClosureBundleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedClosureBundleAdjuster: ClosureBundleModifier {
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

        func adjust(_ item: ClosureBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredClosureBundleAdjuster: ClosureBundleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosureBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the closure bundle steps in order and keeps a trace of each.
    final class ClosureBundleEngine {
        var steps: [any ClosureBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClosureBundle) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ClosureBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClosureBundleEngine(_ flags: Kit.Flags.Registry) -> ClosureBundleEngine {
        return ClosureBundleEngine(
            steps: [
                CapClosureBundleAdjuster(cap: 49725.0),
                FlaggedClosureBundleAdjuster(flags: flags, flag: "closure-bundle-fallback", percent: 2.7),
                TieredClosureBundleAdjuster(bounds: [2630.0, 6009.0, 7061.0, 8312.0], rates: [0.85, 1.05, 1.17, 1.14]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 64072.0
        )
    }
}
