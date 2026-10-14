import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling transfer segment calculation.
    protocol RollingTransferSegmentFactor {
        func describe() -> String
        func adjust(_ item: RollingTransferSegment, value: Double) -> Double
    }

    final class FlaggedRollingTransferSegmentAdjuster: RollingTransferSegmentFactor {
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

        func adjust(_ item: RollingTransferSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingTransferSegmentAdjuster: RollingTransferSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingTransferSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategoryRollingTransferSegmentAdjuster: RollingTransferSegmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RollingTransferSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling transfer segment steps in order and keeps a trace of each.
    final class RollingTransferSegmentEngine {
        var steps: [any RollingTransferSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingTransferSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingTransferSegment) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [RollingTransferSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingTransferSegmentEngine(_ flags: Kit.Flags.Registry) -> RollingTransferSegmentEngine {
        return RollingTransferSegmentEngine(
            steps: [
                FlaggedRollingTransferSegmentAdjuster(
                    flags: flags,
                    flag: "rolling-transfer-segment-seasonal",
                    percent: 5.4
                ),
                CapRollingTransferSegmentAdjuster(cap: 29688.0),
                CategoryRollingTransferSegmentAdjuster(factors: ["online": 0.96, "east": 1.05]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 99635.6
        )
    }
}
