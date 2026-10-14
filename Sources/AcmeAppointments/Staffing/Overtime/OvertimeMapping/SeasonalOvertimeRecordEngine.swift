import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the seasonal overtime record calculation.
    protocol SeasonalOvertimeRecordStep {
        func describe() -> String
        func adjust(_ item: SeasonalOvertimeRecord, value: Double) -> Double
    }

    final class PercentSeasonalOvertimeRecordAdjuster: SeasonalOvertimeRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalOvertimeRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalOvertimeRecordRatioOffsetAdjuster: SeasonalOvertimeRecordStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: SeasonalOvertimeRecord, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RoundingSeasonalOvertimeRecordAdjuster: SeasonalOvertimeRecordStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalOvertimeRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSeasonalOvertimeRecordAdjuster: SeasonalOvertimeRecordStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalOvertimeRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSeasonalOvertimeRecordAdjuster: SeasonalOvertimeRecordStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalOvertimeRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal overtime record steps in order and keeps a trace of each.
    final class SeasonalOvertimeRecordEngine {
        var steps: [any SeasonalOvertimeRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalOvertimeRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalOvertimeRecord) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalOvertimeRecordStep = steps[index]
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

        func evaluateAll(_ items: [SeasonalOvertimeRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalOvertimeRecordEngine() -> SeasonalOvertimeRecordEngine {
        return SeasonalOvertimeRecordEngine(
            steps: [
                PercentSeasonalOvertimeRecordAdjuster(percent: 19.4),
                SeasonalOvertimeRecordRatioOffsetAdjuster(weight: 0.57),
                RoundingSeasonalOvertimeRecordAdjuster(step: 5.0),
                CapSeasonalOvertimeRecordAdjuster(cap: 13231.0),
                MinimumSeasonalOvertimeRecordAdjuster(minimum: 31.1),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 67125.7
        )
    }
}
