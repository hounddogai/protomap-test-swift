import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the pending order set group calculation.
    protocol PendingOrderSetGroupAdjuster {
        func describe() -> String
        func adjust(_ item: PendingOrderSetGroup, value: Double) -> Double
    }

    final class CapPendingOrderSetGroupAdjuster: PendingOrderSetGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingOrderSetGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PendingOrderSetGroupScoreOffsetAdjuster: PendingOrderSetGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: PendingOrderSetGroup, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class FlaggedPendingOrderSetGroupAdjuster: PendingOrderSetGroupAdjuster {
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

        func adjust(_ item: PendingOrderSetGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPendingOrderSetGroupAdjuster: PendingOrderSetGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingOrderSetGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitPendingOrderSetGroupAdjuster: PendingOrderSetGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PendingOrderSetGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPendingOrderSetGroupAdjuster: PendingOrderSetGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingOrderSetGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending order set group steps in order and keeps a trace of each.
    final class PendingOrderSetGroupEngine {
        var steps: [any PendingOrderSetGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingOrderSetGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingOrderSetGroup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingOrderSetGroupAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingOrderSetGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingOrderSetGroupEngine(_ flags: Kit.Flags.Registry) -> PendingOrderSetGroupEngine {
        return PendingOrderSetGroupEngine(
            steps: [
                CapPendingOrderSetGroupAdjuster(cap: 2767.0),
                PendingOrderSetGroupScoreOffsetAdjuster(weight: 1.86),
                FlaggedPendingOrderSetGroupAdjuster(
                    flags: flags,
                    flag: "pending-order-set-group-scheduled",
                    percent: -3.0
                ),
                PercentPendingOrderSetGroupAdjuster(percent: -18.2),
                UnitPendingOrderSetGroupAdjuster(factors: ["east": 0.84, "central": 1.21]),
                TieredPendingOrderSetGroupAdjuster(
                    bounds: [2480.0, 7597.0, 7710.0, 9928.0],
                    rates: [1.01, 1.07, 1.16, 0.89]
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 75947.0
        )
    }
}
