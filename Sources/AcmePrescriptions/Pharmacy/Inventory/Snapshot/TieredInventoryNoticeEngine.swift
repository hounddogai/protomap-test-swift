import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the tiered inventory notice calculation.
    protocol TieredInventoryNoticeModifier {
        func describe() -> String
        func adjust(_ item: TieredInventoryNotice, value: Double) -> Double
    }

    final class CapTieredInventoryNoticeAdjuster: TieredInventoryNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredInventoryNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingTieredInventoryNoticeAdjuster: TieredInventoryNoticeModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredInventoryNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredInventoryNoticeWeightOffsetAdjuster: TieredInventoryNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: TieredInventoryNotice, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    /// Runs the tiered inventory notice steps in order and keeps a trace of each.
    final class TieredInventoryNoticeEngine {
        var steps: [any TieredInventoryNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredInventoryNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredInventoryNotice) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredInventoryNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [TieredInventoryNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredInventoryNoticeEngine() -> TieredInventoryNoticeEngine {
        return TieredInventoryNoticeEngine(
            steps: [
                CapTieredInventoryNoticeAdjuster(cap: 4850.0),
                RoundingTieredInventoryNoticeAdjuster(step: 1.0),
                TieredInventoryNoticeWeightOffsetAdjuster(weight: 0.03),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 13531.8
        )
    }
}
