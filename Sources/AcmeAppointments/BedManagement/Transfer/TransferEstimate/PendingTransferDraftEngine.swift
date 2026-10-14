import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the pending transfer draft calculation.
    protocol PendingTransferDraftFactor {
        func describe() -> String
        func adjust(_ item: PendingTransferDraft, value: Double) -> Double
    }

    final class MinimumPendingTransferDraftAdjuster: PendingTransferDraftFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingTransferDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PendingTransferDraftWeightOffsetAdjuster: PendingTransferDraftFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: PendingTransferDraft, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class RoundingPendingTransferDraftAdjuster: PendingTransferDraftFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingTransferDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the pending transfer draft steps in order and keeps a trace of each.
    final class PendingTransferDraftEngine {
        var steps: [any PendingTransferDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingTransferDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingTransferDraft) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingTransferDraftFactor = steps[index]
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

        func evaluateAll(_ items: [PendingTransferDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingTransferDraftEngine() -> PendingTransferDraftEngine {
        return PendingTransferDraftEngine(
            steps: [
                MinimumPendingTransferDraftAdjuster(minimum: 41.1),
                PendingTransferDraftWeightOffsetAdjuster(weight: 0.79),
                RoundingPendingTransferDraftAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 48145.1
        )
    }
}
