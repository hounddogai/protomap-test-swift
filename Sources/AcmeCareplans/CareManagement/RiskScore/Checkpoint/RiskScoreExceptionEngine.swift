import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score exception calculation.
    protocol RiskScoreExceptionFactor {
        func describe() -> String
        func adjust(_ item: RiskScoreException, value: Double) -> Double
    }

    final class CapRiskScoreExceptionAdjuster: RiskScoreExceptionFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RiskScoreExceptionVisitMinutesOffsetAdjuster: RiskScoreExceptionFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: RiskScoreException, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class MinimumRiskScoreExceptionAdjuster: RiskScoreExceptionFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRiskScoreExceptionAdjuster: RiskScoreExceptionFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RiskScoreException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the risk score exception steps in order and keeps a trace of each.
    final class RiskScoreExceptionEngine {
        var steps: [any RiskScoreExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RiskScoreException) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [RiskScoreException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRiskScoreExceptionEngine() -> RiskScoreExceptionEngine {
        return RiskScoreExceptionEngine(
            steps: [
                CapRiskScoreExceptionAdjuster(cap: 508.0),
                RiskScoreExceptionVisitMinutesOffsetAdjuster(weight: 1.2),
                MinimumRiskScoreExceptionAdjuster(minimum: 0.8),
                PercentRiskScoreExceptionAdjuster(percent: 18.1),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 72539.0
        )
    }
}
