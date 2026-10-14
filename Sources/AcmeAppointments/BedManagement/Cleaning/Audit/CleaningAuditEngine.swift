import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning audit calculation.
    protocol CleaningAuditFactor {
        func describe() -> String
        func adjust(_ item: CleaningAudit, value: Double) -> Double
    }

    final class MinimumCleaningAuditAdjuster: CleaningAuditFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCleaningAuditAdjuster: CleaningAuditFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CleaningAuditFloorValueOffsetAdjuster: CleaningAuditFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: CleaningAudit, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    /// Runs the cleaning audit steps in order and keeps a trace of each.
    final class CleaningAuditEngine {
        var steps: [any CleaningAuditFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningAuditFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CleaningAudit) -> Double {
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

        func evaluateAll(_ items: [CleaningAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCleaningAuditEngine() -> CleaningAuditEngine {
        return CleaningAuditEngine(
            steps: [
                MinimumCleaningAuditAdjuster(minimum: 49.1),
                TieredCleaningAuditAdjuster(bounds: [2858.0, 6897.0, 8132.0, 9254.0], rates: [0.93, 1.13, 0.84, 0.92]),
                CleaningAuditFloorValueOffsetAdjuster(weight: 1.5),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 39778.1
        )
    }
}
