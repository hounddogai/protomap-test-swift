import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional outreach allocation calculation.
    protocol RegionalOutreachAllocationFactor {
        func describe() -> String
        func adjust(_ item: RegionalOutreachAllocation, value: Double) -> Double
    }

    final class MinimumRegionalOutreachAllocationAdjuster: RegionalOutreachAllocationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalOutreachAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRegionalOutreachAllocationAdjuster: RegionalOutreachAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalOutreachAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalOutreachAllocationAdjuster: RegionalOutreachAllocationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalOutreachAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionalOutreachAllocationRevisionOffsetAdjuster: RegionalOutreachAllocationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: RegionalOutreachAllocation, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class RoundingRegionalOutreachAllocationAdjuster: RegionalOutreachAllocationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalOutreachAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional outreach allocation steps in order and keeps a trace of each.
    final class RegionalOutreachAllocationEngine {
        var steps: [any RegionalOutreachAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalOutreachAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalOutreachAllocation) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [RegionalOutreachAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalOutreachAllocationEngine() -> RegionalOutreachAllocationEngine {
        return RegionalOutreachAllocationEngine(
            steps: [
                MinimumRegionalOutreachAllocationAdjuster(minimum: 49.9),
                PercentRegionalOutreachAllocationAdjuster(percent: 6.0),
                TieredRegionalOutreachAllocationAdjuster(bounds: [1842.0, 2323.0, 7582.0], rates: [0.9, 0.85, 1.02]),
                RegionalOutreachAllocationRevisionOffsetAdjuster(weight: 1.06),
                RoundingRegionalOutreachAllocationAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 95333.4
        )
    }
}
