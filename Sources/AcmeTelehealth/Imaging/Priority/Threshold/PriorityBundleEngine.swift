import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority bundle calculation.
    protocol PriorityBundleFactor {
        func describe() -> String
        func adjust(_ item: PriorityBundle, value: Double) -> Double
    }

    final class PriorityBundleAmountOffsetAdjuster: PriorityBundleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: PriorityBundle, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class MinimumPriorityBundleAdjuster: PriorityBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPriorityBundleAdjuster: PriorityBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PriorityBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPriorityBundleAdjuster: PriorityBundleFactor {
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

        func adjust(_ item: PriorityBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the priority bundle steps in order and keeps a trace of each.
    final class PriorityBundleEngine {
        var steps: [any PriorityBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PriorityBundle) -> Double {
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

        func evaluateAll(_ items: [PriorityBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPriorityBundleEngine(_ flags: Kit.Flags.Registry) -> PriorityBundleEngine {
        return PriorityBundleEngine(
            steps: [
                PriorityBundleAmountOffsetAdjuster(weight: 0.55),
                MinimumPriorityBundleAdjuster(minimum: 42.2),
                CapPriorityBundleAdjuster(cap: 35402.0),
                FlaggedPriorityBundleAdjuster(flags: flags, flag: "priority-bundle-capped", percent: -9.8),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 65428.5
        )
    }
}
