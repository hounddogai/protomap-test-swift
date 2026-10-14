import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol schedule calculation.
    protocol CareProtocolScheduleModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolSchedule, value: Double) -> Double
    }

    final class CareProtocolScheduleBatchSizeOffsetAdjuster: CareProtocolScheduleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: CareProtocolSchedule, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class TieredCareProtocolScheduleAdjuster: CareProtocolScheduleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCareProtocolScheduleAdjuster: CareProtocolScheduleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the care protocol schedule steps in order and keeps a trace of each.
    final class CareProtocolScheduleEngine {
        var steps: [any CareProtocolScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareProtocolSchedule) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolScheduleModifier = steps[index]
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

        func evaluateAll(_ items: [CareProtocolSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareProtocolScheduleEngine() -> CareProtocolScheduleEngine {
        return CareProtocolScheduleEngine(
            steps: [
                CareProtocolScheduleBatchSizeOffsetAdjuster(weight: 1.38),
                TieredCareProtocolScheduleAdjuster(
                    bounds: [1418.0, 2568.0, 4193.0, 8140.0],
                    rates: [1.12, 1.05, 1.02, 1.16]
                ),
                MinimumCareProtocolScheduleAdjuster(minimum: 45.1),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 8077.6
        )
    }
}
