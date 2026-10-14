import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board window calculation.
    protocol BedBoardWindowFactor {
        func describe() -> String
        func adjust(_ item: BedBoardWindow, value: Double) -> Double
    }

    final class TitleBedBoardWindowAdjuster: BedBoardWindowFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BedBoardWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumBedBoardWindowAdjuster: BedBoardWindowFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBedBoardWindowAdjuster: BedBoardWindowFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapBedBoardWindowAdjuster: BedBoardWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class BedBoardWindowCapacityOffsetAdjuster: BedBoardWindowFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: BedBoardWindow, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class PercentBedBoardWindowAdjuster: BedBoardWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BedBoardWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the bed board window steps in order and keeps a trace of each.
    final class BedBoardWindowEngine {
        var steps: [any BedBoardWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BedBoardWindow) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardWindowFactor = steps[index]
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

        func evaluateAll(_ items: [BedBoardWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBedBoardWindowEngine() -> BedBoardWindowEngine {
        return BedBoardWindowEngine(
            steps: [
                TitleBedBoardWindowAdjuster(factors: ["central": 1.02]),
                MinimumBedBoardWindowAdjuster(minimum: 20.0),
                RoundingBedBoardWindowAdjuster(step: 0.5),
                CapBedBoardWindowAdjuster(cap: 10708.0),
                BedBoardWindowCapacityOffsetAdjuster(weight: 0.7),
                PercentBedBoardWindowAdjuster(percent: 7.3),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 82953.5
        )
    }
}
