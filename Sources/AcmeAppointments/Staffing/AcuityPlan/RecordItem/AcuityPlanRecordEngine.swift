import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan record calculation.
    protocol AcuityPlanRecordAdjuster {
        func describe() -> String
        func adjust(_ item: AcuityPlanRecord, value: Double) -> Double
    }

    final class PercentAcuityPlanRecordAdjuster: AcuityPlanRecordAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAcuityPlanRecordAdjuster: AcuityPlanRecordAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AcuityPlanRecordCeilingOffsetAdjuster: AcuityPlanRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: AcuityPlanRecord, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the acuity plan record steps in order and keeps a trace of each.
    final class AcuityPlanRecordEngine {
        var steps: [any AcuityPlanRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AcuityPlanRecord) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanRecordEngine() -> AcuityPlanRecordEngine {
        return AcuityPlanRecordEngine(
            steps: [
                PercentAcuityPlanRecordAdjuster(percent: 17.0),
                RoundingAcuityPlanRecordAdjuster(step: 0.25),
                AcuityPlanRecordCeilingOffsetAdjuster(weight: 1.4),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 10948.5
        )
    }
}
