import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped care gap assignment calculation.
    protocol CappedCareGapAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: CappedCareGapAssignment, value: Double) -> Double
    }

    final class RoundingCappedCareGapAssignmentAdjuster: CappedCareGapAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedCareGapAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCappedCareGapAssignmentAdjuster: CappedCareGapAssignmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedCareGapAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CappedCareGapAssignmentRefillsOffsetAdjuster: CappedCareGapAssignmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: CappedCareGapAssignment, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    /// Runs the capped care gap assignment steps in order and keeps a trace of each.
    final class CappedCareGapAssignmentEngine {
        var steps: [any CappedCareGapAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCareGapAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedCareGapAssignment) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [CappedCareGapAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedCareGapAssignmentEngine() -> CappedCareGapAssignmentEngine {
        return CappedCareGapAssignmentEngine(
            steps: [
                RoundingCappedCareGapAssignmentAdjuster(step: 0.5),
                TieredCappedCareGapAssignmentAdjuster(
                    bounds: [6224.0, 7336.0, 7658.0, 8970.0],
                    rates: [0.96, 0.9, 1.02, 1.17]
                ),
                CappedCareGapAssignmentRefillsOffsetAdjuster(weight: 1.79),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 97275.1
        )
    }
}
