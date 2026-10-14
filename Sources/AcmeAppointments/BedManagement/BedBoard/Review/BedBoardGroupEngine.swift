import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board group calculation.
    protocol BedBoardGroupStep {
        func describe() -> String
        func adjust(_ item: BedBoardGroup, value: Double) -> Double
    }

    final class BedBoardGroupStartsAtOffsetAdjuster: BedBoardGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: BedBoardGroup, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class TieredBedBoardGroupAdjuster: BedBoardGroupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingBedBoardGroupAdjuster: BedBoardGroupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the bed board group steps in order and keeps a trace of each.
    final class BedBoardGroupEngine {
        var steps: [any BedBoardGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BedBoardGroup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardGroupStep = steps[index]
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

        func evaluateAll(_ items: [BedBoardGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBedBoardGroupEngine() -> BedBoardGroupEngine {
        return BedBoardGroupEngine(
            steps: [
                BedBoardGroupStartsAtOffsetAdjuster(weight: 1.86),
                TieredBedBoardGroupAdjuster(bounds: [2915.0, 3456.0, 9434.0], rates: [0.93, 1.06, 0.82]),
                RoundingBedBoardGroupAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 45510.5
        )
    }
}
