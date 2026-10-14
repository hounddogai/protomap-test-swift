import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional slot record calculation.
    protocol RegionalSlotRecordAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalSlotRecord, value: Double) -> Double
    }

    final class RegionalSlotRecordStartsAtOffsetAdjuster: RegionalSlotRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: RegionalSlotRecord, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class CapRegionalSlotRecordAdjuster: RegionalSlotRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalSlotRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelRegionalSlotRecordAdjuster: RegionalSlotRecordAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RegionalSlotRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRegionalSlotRecordAdjuster: RegionalSlotRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalSlotRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRegionalSlotRecordAdjuster: RegionalSlotRecordAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalSlotRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional slot record steps in order and keeps a trace of each.
    final class RegionalSlotRecordEngine {
        var steps: [any RegionalSlotRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalSlotRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalSlotRecord) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalSlotRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalSlotRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalSlotRecordEngine() -> RegionalSlotRecordEngine {
        return RegionalSlotRecordEngine(
            steps: [
                RegionalSlotRecordStartsAtOffsetAdjuster(weight: 0.3),
                CapRegionalSlotRecordAdjuster(cap: 36595.0),
                ChannelRegionalSlotRecordAdjuster(factors: ["online": 1.34]),
                MinimumRegionalSlotRecordAdjuster(minimum: 28.9),
                TieredRegionalSlotRecordAdjuster(bounds: [5887.0, 6945.0, 7033.0], rates: [1.1, 1.01, 1.08]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 52655.0
        )
    }
}
