import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the pending priority draft calculation.
    protocol PendingPriorityDraftAdjuster {
        func describe() -> String
        func adjust(_ item: PendingPriorityDraft, value: Double) -> Double
    }

    final class CapPendingPriorityDraftAdjuster: PendingPriorityDraftAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingPriorityDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPendingPriorityDraftAdjuster: PendingPriorityDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingPriorityDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PendingPriorityDraftCapacityOffsetAdjuster: PendingPriorityDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: PendingPriorityDraft, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class TieredPendingPriorityDraftAdjuster: PendingPriorityDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingPriorityDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPendingPriorityDraftAdjuster: PendingPriorityDraftAdjuster {
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

        func adjust(_ item: PendingPriorityDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingPriorityDraftAdjuster: PendingPriorityDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingPriorityDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending priority draft steps in order and keeps a trace of each.
    final class PendingPriorityDraftEngine {
        var steps: [any PendingPriorityDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingPriorityDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingPriorityDraft) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingPriorityDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingPriorityDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingPriorityDraftEngine(_ flags: Kit.Flags.Registry) -> PendingPriorityDraftEngine {
        return PendingPriorityDraftEngine(
            steps: [
                CapPendingPriorityDraftAdjuster(cap: 574.0),
                MinimumPendingPriorityDraftAdjuster(minimum: 39.2),
                PendingPriorityDraftCapacityOffsetAdjuster(weight: 0.6),
                TieredPendingPriorityDraftAdjuster(
                    bounds: [1223.0, 1773.0, 3770.0, 6787.0],
                    rates: [0.81, 0.85, 0.9, 1.13]
                ),
                FlaggedPendingPriorityDraftAdjuster(
                    flags: flags,
                    flag: "pending-priority-draft-fallback",
                    percent: 0.7
                ),
                RoundingPendingPriorityDraftAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 86993.7
        )
    }
}
