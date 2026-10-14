import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime record calculation.
    protocol OvertimeRecordAdjuster {
        func describe() -> String
        func adjust(_ item: OvertimeRecord, value: Double) -> Double
    }

    final class PercentOvertimeRecordAdjuster: OvertimeRecordAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingOvertimeRecordAdjuster: OvertimeRecordAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocaleOvertimeRecordAdjuster: OvertimeRecordAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: OvertimeRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class OvertimeRecordEndsAtOffsetAdjuster: OvertimeRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: OvertimeRecord, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class MinimumOvertimeRecordAdjuster: OvertimeRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the overtime record steps in order and keeps a trace of each.
    final class OvertimeRecordEngine {
        var steps: [any OvertimeRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: OvertimeRecord) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimeRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [OvertimeRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultOvertimeRecordEngine() -> OvertimeRecordEngine {
        return OvertimeRecordEngine(
            steps: [
                PercentOvertimeRecordAdjuster(percent: 5.7),
                RoundingOvertimeRecordAdjuster(step: 0.1),
                LocaleOvertimeRecordAdjuster(factors: ["north": 0.88, "east": 1.15, "west": 0.78]),
                OvertimeRecordEndsAtOffsetAdjuster(weight: 0.57),
                MinimumOvertimeRecordAdjuster(minimum: 5.6),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 42869.6
        )
    }
}
