import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set draft calculation.
    protocol OrderSetDraftFactor {
        func describe() -> String
        func adjust(_ item: OrderSetDraft, value: Double) -> Double
    }

    final class OrderSetDraftVisitMinutesOffsetAdjuster: OrderSetDraftFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: OrderSetDraft, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class RoundingOrderSetDraftAdjuster: OrderSetDraftFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapOrderSetDraftAdjuster: OrderSetDraftFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedOrderSetDraftAdjuster: OrderSetDraftFactor {
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

        func adjust(_ item: OrderSetDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleOrderSetDraftAdjuster: OrderSetDraftFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: OrderSetDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the order set draft steps in order and keeps a trace of each.
    final class OrderSetDraftEngine {
        var steps: [any OrderSetDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OrderSetDraft) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [OrderSetDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOrderSetDraftEngine(_ flags: Kit.Flags.Registry) -> OrderSetDraftEngine {
        return OrderSetDraftEngine(
            steps: [
                OrderSetDraftVisitMinutesOffsetAdjuster(weight: 0.35),
                RoundingOrderSetDraftAdjuster(step: 0.5),
                CapOrderSetDraftAdjuster(cap: 17240.0),
                FlaggedOrderSetDraftAdjuster(flags: flags, flag: "order-set-draft-tiered", percent: 5.0),
                LocaleOrderSetDraftAdjuster(factors: ["east": 1.03, "west": 1.02]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 43320.8
        )
    }
}
