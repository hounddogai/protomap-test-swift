import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning assignment calculation.
    protocol CleaningAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: CleaningAssignment, value: Double) -> Double
    }

    final class MinimumCleaningAssignmentAdjuster: CleaningAssignmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCleaningAssignmentAdjuster: CleaningAssignmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionCleaningAssignmentAdjuster: CleaningAssignmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: CleaningAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCleaningAssignmentAdjuster: CleaningAssignmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCleaningAssignmentAdjuster: CleaningAssignmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the cleaning assignment steps in order and keeps a trace of each.
    final class CleaningAssignmentEngine {
        var steps: [any CleaningAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningAssignment) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningAssignmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [CleaningAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningAssignmentEngine() -> CleaningAssignmentEngine {
        return CleaningAssignmentEngine(
            steps: [
                MinimumCleaningAssignmentAdjuster(minimum: 40.5),
                TieredCleaningAssignmentAdjuster(bounds: [2846.0, 8475.0], rates: [1.18, 1.02]),
                RegionCleaningAssignmentAdjuster(factors: ["central": 1.07, "retail": 0.82]),
                CapCleaningAssignmentAdjuster(cap: 32614.0),
                PercentCleaningAssignmentAdjuster(percent: -2.8),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 30732.0
        )
    }
}
