import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the batched task manifest calculation.
    protocol BatchedTaskManifestModifier {
        func describe() -> String
        func adjust(_ item: BatchedTaskManifest, value: Double) -> Double
    }

    final class FlaggedBatchedTaskManifestAdjuster: BatchedTaskManifestModifier {
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

        func adjust(_ item: BatchedTaskManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedTaskManifestAdjuster: BatchedTaskManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedTaskManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBatchedTaskManifestAdjuster: BatchedTaskManifestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedTaskManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched task manifest steps in order and keeps a trace of each.
    final class BatchedTaskManifestEngine {
        var steps: [any BatchedTaskManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedTaskManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedTaskManifest) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [BatchedTaskManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedTaskManifestEngine(_ flags: Kit.Flags.Registry) -> BatchedTaskManifestEngine {
        return BatchedTaskManifestEngine(
            steps: [
                FlaggedBatchedTaskManifestAdjuster(flags: flags, flag: "batched-task-manifest-fallback", percent: 9.5),
                CapBatchedTaskManifestAdjuster(cap: 37281.0),
                TieredBatchedTaskManifestAdjuster(bounds: [1005.0, 6857.0, 9164.0], rates: [1.0, 1.03, 1.18]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 74077.4
        )
    }
}
