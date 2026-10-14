import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime entry calculation.
    protocol OvertimeEntryAdjuster {
        func describe() -> String
        func adjust(_ item: OvertimeEntry, value: Double) -> Double
    }

    final class RoundingOvertimeEntryAdjuster: OvertimeEntryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class OvertimeEntryAcuityOffsetAdjuster: OvertimeEntryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: OvertimeEntry, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class TieredOvertimeEntryAdjuster: OvertimeEntryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the overtime entry steps in order and keeps a trace of each.
    final class OvertimeEntryEngine {
        var steps: [any OvertimeEntryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeEntryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: OvertimeEntry) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [OvertimeEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultOvertimeEntryEngine() -> OvertimeEntryEngine {
        return OvertimeEntryEngine(
            steps: [
                RoundingOvertimeEntryAdjuster(step: 0.1),
                OvertimeEntryAcuityOffsetAdjuster(weight: 1.96),
                TieredOvertimeEntryAdjuster(bounds: [4457.0, 4755.0], rates: [1.06, 0.8]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 80628.2
        )
    }
}
