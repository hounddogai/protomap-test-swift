import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan record calculation.
    protocol DischargePlanRecordStep {
        func describe() -> String
        func adjust(_ item: DischargePlanRecord, value: Double) -> Double
    }

    final class TieredDischargePlanRecordAdjuster: DischargePlanRecordStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DischargePlanRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDischargePlanRecordAdjuster: DischargePlanRecordStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingDischargePlanRecordAdjuster: DischargePlanRecordStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DischargePlanRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the discharge plan record steps in order and keeps a trace of each.
    final class DischargePlanRecordEngine {
        var steps: [any DischargePlanRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DischargePlanRecord) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanRecordStep = steps[index]
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

        func evaluateAll(_ items: [DischargePlanRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDischargePlanRecordEngine() -> DischargePlanRecordEngine {
        return DischargePlanRecordEngine(
            steps: [
                TieredDischargePlanRecordAdjuster(bounds: [3581.0, 5794.0], rates: [0.93, 0.99]),
                CapDischargePlanRecordAdjuster(cap: 4172.0),
                RoundingDischargePlanRecordAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 56741.1
        )
    }
}
