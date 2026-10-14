import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling priority agreement calculation.
    protocol RollingPriorityAgreementStep {
        func describe() -> String
        func adjust(_ item: RollingPriorityAgreement, value: Double) -> Double
    }

    final class RoundingRollingPriorityAgreementAdjuster: RollingPriorityAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingPriorityAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRollingPriorityAgreementAdjuster: RollingPriorityAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingPriorityAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RollingPriorityAgreementVisitMinutesOffsetAdjuster: RollingPriorityAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: RollingPriorityAgreement, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    /// Runs the rolling priority agreement steps in order and keeps a trace of each.
    final class RollingPriorityAgreementEngine {
        var steps: [any RollingPriorityAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingPriorityAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingPriorityAgreement) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [RollingPriorityAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingPriorityAgreementEngine() -> RollingPriorityAgreementEngine {
        return RollingPriorityAgreementEngine(
            steps: [
                RoundingRollingPriorityAgreementAdjuster(step: 5.0),
                TieredRollingPriorityAgreementAdjuster(
                    bounds: [763.0, 6466.0, 7333.0, 9204.0],
                    rates: [0.85, 0.95, 1.03, 0.81]
                ),
                RollingPriorityAgreementVisitMinutesOffsetAdjuster(weight: 1.77),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 29284.6
        )
    }
}
