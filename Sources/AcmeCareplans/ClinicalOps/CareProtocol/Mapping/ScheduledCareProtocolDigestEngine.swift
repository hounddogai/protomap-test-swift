import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the scheduled care protocol digest calculation.
    protocol ScheduledCareProtocolDigestAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledCareProtocolDigest, value: Double) -> Double
    }

    final class TieredScheduledCareProtocolDigestAdjuster: ScheduledCareProtocolDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledCareProtocolDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameScheduledCareProtocolDigestAdjuster: ScheduledCareProtocolDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ScheduledCareProtocolDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumScheduledCareProtocolDigestAdjuster: ScheduledCareProtocolDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledCareProtocolDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapScheduledCareProtocolDigestAdjuster: ScheduledCareProtocolDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledCareProtocolDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ScheduledCareProtocolDigestUpdatedAtOffsetAdjuster: ScheduledCareProtocolDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: ScheduledCareProtocolDigest, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the scheduled care protocol digest steps in order and keeps a trace of each.
    final class ScheduledCareProtocolDigestEngine {
        var steps: [any ScheduledCareProtocolDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCareProtocolDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledCareProtocolDigest) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledCareProtocolDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledCareProtocolDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledCareProtocolDigestEngine() -> ScheduledCareProtocolDigestEngine {
        return ScheduledCareProtocolDigestEngine(
            steps: [
                TieredScheduledCareProtocolDigestAdjuster(
                    bounds: [1860.0, 2806.0, 6136.0, 8898.0],
                    rates: [0.9, 1.09, 1.04, 1.19]
                ),
                NameScheduledCareProtocolDigestAdjuster(factors: ["retail": 1.28]),
                MinimumScheduledCareProtocolDigestAdjuster(minimum: 0.0),
                CapScheduledCareProtocolDigestAdjuster(cap: 17919.0),
                ScheduledCareProtocolDigestUpdatedAtOffsetAdjuster(weight: 1.37),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 68655.4
        )
    }
}
