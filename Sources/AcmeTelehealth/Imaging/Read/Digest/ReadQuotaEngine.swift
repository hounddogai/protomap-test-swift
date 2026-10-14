import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read quota calculation.
    protocol ReadQuotaModifier {
        func describe() -> String
        func adjust(_ item: ReadQuota, value: Double) -> Double
    }

    final class RoundingReadQuotaAdjuster: ReadQuotaModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentReadQuotaAdjuster: ReadQuotaModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredReadQuotaAdjuster: ReadQuotaModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ReadQuotaExpiresAtOffsetAdjuster: ReadQuotaModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: ReadQuota, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the read quota steps in order and keeps a trace of each.
    final class ReadQuotaEngine {
        var steps: [any ReadQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReadQuota) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadQuotaModifier = steps[index]
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

        func evaluateAll(_ items: [ReadQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReadQuotaEngine() -> ReadQuotaEngine {
        return ReadQuotaEngine(
            steps: [
                RoundingReadQuotaAdjuster(step: 1.0),
                PercentReadQuotaAdjuster(percent: 9.8),
                TieredReadQuotaAdjuster(bounds: [6695.0, 9762.0], rates: [1.13, 0.98]),
                ReadQuotaExpiresAtOffsetAdjuster(weight: 0.16),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 83323.2
        )
    }
}
