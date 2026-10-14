import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the seasonal shift audit calculation.
    protocol SeasonalShiftAuditModifier {
        func describe() -> String
        func adjust(_ item: SeasonalShiftAudit, value: Double) -> Double
    }

    final class RoundingSeasonalShiftAuditAdjuster: SeasonalShiftAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalShiftAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SeasonalShiftAuditCapacityOffsetAdjuster: SeasonalShiftAuditModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: SeasonalShiftAudit, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class TieredSeasonalShiftAuditAdjuster: SeasonalShiftAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalShiftAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapSeasonalShiftAuditAdjuster: SeasonalShiftAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalShiftAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSeasonalShiftAuditAdjuster: SeasonalShiftAuditModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalShiftAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal shift audit steps in order and keeps a trace of each.
    final class SeasonalShiftAuditEngine {
        var steps: [any SeasonalShiftAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalShiftAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalShiftAudit) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalShiftAuditModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalShiftAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalShiftAuditEngine() -> SeasonalShiftAuditEngine {
        return SeasonalShiftAuditEngine(
            steps: [
                RoundingSeasonalShiftAuditAdjuster(step: 1.0),
                SeasonalShiftAuditCapacityOffsetAdjuster(weight: 1.51),
                TieredSeasonalShiftAuditAdjuster(
                    bounds: [289.0, 1362.0, 3089.0, 8810.0],
                    rates: [0.89, 1.07, 0.87, 0.93]
                ),
                CapSeasonalShiftAuditAdjuster(cap: 26914.0),
                PercentSeasonalShiftAuditAdjuster(percent: 1.2),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 87778.9
        )
    }
}
