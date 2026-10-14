import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the capped bed board record calculation.
    protocol CappedBedBoardRecordFactor {
        func describe() -> String
        func adjust(_ item: CappedBedBoardRecord, value: Double) -> Double
    }

    final class CapCappedBedBoardRecordAdjuster: CappedBedBoardRecordFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedBedBoardRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SegmentCappedBedBoardRecordAdjuster: CappedBedBoardRecordFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: CappedBedBoardRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCappedBedBoardRecordAdjuster: CappedBedBoardRecordFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedBedBoardRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCappedBedBoardRecordAdjuster: CappedBedBoardRecordFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedBedBoardRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped bed board record steps in order and keeps a trace of each.
    final class CappedBedBoardRecordEngine {
        var steps: [any CappedBedBoardRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedBedBoardRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedBedBoardRecord) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedBedBoardRecordFactor = steps[index]
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

        func evaluateAll(_ items: [CappedBedBoardRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedBedBoardRecordEngine() -> CappedBedBoardRecordEngine {
        return CappedBedBoardRecordEngine(
            steps: [
                CapCappedBedBoardRecordAdjuster(cap: 32320.0),
                SegmentCappedBedBoardRecordAdjuster(factors: ["central": 0.88]),
                RoundingCappedBedBoardRecordAdjuster(step: 5.0),
                TieredCappedBedBoardRecordAdjuster(
                    bounds: [4423.0, 6364.0, 8102.0, 9336.0],
                    rates: [0.92, 0.88, 1.09, 1.19]
                ),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 43409.2
        )
    }
}
