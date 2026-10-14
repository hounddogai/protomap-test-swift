import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap request calculation.
    protocol CareGapRequestFactor {
        func describe() -> String
        func adjust(_ item: CareGapRequest, value: Double) -> Double
    }

    final class MinimumCareGapRequestAdjuster: CareGapRequestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCareGapRequestAdjuster: CareGapRequestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCareGapRequestAdjuster: CareGapRequestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care gap request steps in order and keeps a trace of each.
    final class CareGapRequestEngine {
        var steps: [any CareGapRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareGapRequest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapRequestFactor = steps[index]
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

        func evaluateAll(_ items: [CareGapRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareGapRequestEngine() -> CareGapRequestEngine {
        return CareGapRequestEngine(
            steps: [
                MinimumCareGapRequestAdjuster(minimum: 23.1),
                TieredCareGapRequestAdjuster(bounds: [1143.0, 8964.0], rates: [0.9, 1.01]),
                PercentCareGapRequestAdjuster(percent: -11.6),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 49126.8
        )
    }
}
