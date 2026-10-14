import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board score calculation.
    protocol BedBoardScoreAdjuster {
        func describe() -> String
        func adjust(_ item: BedBoardScore, value: Double) -> Double
    }

    final class MinimumBedBoardScoreAdjuster: BedBoardScoreAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredBedBoardScoreAdjuster: BedBoardScoreAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingBedBoardScoreAdjuster: BedBoardScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the bed board score steps in order and keeps a trace of each.
    final class BedBoardScoreEngine {
        var steps: [any BedBoardScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BedBoardScore) -> Double {
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

        func evaluateAll(_ items: [BedBoardScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBedBoardScoreEngine() -> BedBoardScoreEngine {
        return BedBoardScoreEngine(
            steps: [
                MinimumBedBoardScoreAdjuster(minimum: 40.3),
                TieredBedBoardScoreAdjuster(bounds: [4752.0, 5058.0, 5487.0, 7162.0], rates: [1.0, 1.16, 0.98, 1.15]),
                RoundingBedBoardScoreAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 16613.5
        )
    }
}
