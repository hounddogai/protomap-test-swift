import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime manifest calculation.
    protocol OvertimeManifestAdjuster {
        func describe() -> String
        func adjust(_ item: OvertimeManifest, value: Double) -> Double
    }

    final class OvertimeManifestWeightOffsetAdjuster: OvertimeManifestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: OvertimeManifest, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TieredOvertimeManifestAdjuster: OvertimeManifestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumOvertimeManifestAdjuster: OvertimeManifestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the overtime manifest steps in order and keeps a trace of each.
    final class OvertimeManifestEngine {
        var steps: [any OvertimeManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OvertimeManifest) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimeManifestAdjuster = steps[index]
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

        func evaluateAll(_ items: [OvertimeManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOvertimeManifestEngine() -> OvertimeManifestEngine {
        return OvertimeManifestEngine(
            steps: [
                OvertimeManifestWeightOffsetAdjuster(weight: 0.24),
                TieredOvertimeManifestAdjuster(bounds: [1646.0, 2412.0, 4530.0], rates: [1.12, 0.91, 1.19]),
                MinimumOvertimeManifestAdjuster(minimum: 3.6),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 18492.0
        )
    }
}
