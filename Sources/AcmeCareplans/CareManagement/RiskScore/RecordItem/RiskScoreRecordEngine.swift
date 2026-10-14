import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score record calculation.
    protocol RiskScoreRecordFactor {
        func describe() -> String
        func adjust(_ item: RiskScoreRecord, value: Double) -> Double
    }

    final class CapRiskScoreRecordAdjuster: RiskScoreRecordFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRiskScoreRecordAdjuster: RiskScoreRecordFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRiskScoreRecordAdjuster: RiskScoreRecordFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the risk score record steps in order and keeps a trace of each.
    final class RiskScoreRecordEngine {
        var steps: [any RiskScoreRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RiskScoreRecord) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreRecordFactor = steps[index]
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

        func evaluateAll(_ items: [RiskScoreRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRiskScoreRecordEngine() -> RiskScoreRecordEngine {
        return RiskScoreRecordEngine(
            steps: [
                CapRiskScoreRecordAdjuster(cap: 35151.0),
                TieredRiskScoreRecordAdjuster(
                    bounds: [5562.0, 5953.0, 7271.0, 8961.0],
                    rates: [0.93, 1.16, 0.81, 0.94]
                ),
                RoundingRiskScoreRecordAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 31603.2
        )
    }
}
