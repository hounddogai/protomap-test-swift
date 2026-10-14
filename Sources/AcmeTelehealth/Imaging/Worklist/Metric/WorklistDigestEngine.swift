import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist digest calculation.
    protocol WorklistDigestAdjuster {
        func describe() -> String
        func adjust(_ item: WorklistDigest, value: Double) -> Double
    }

    final class RoundingWorklistDigestAdjuster: WorklistDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredWorklistDigestAdjuster: WorklistDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WorklistDigestEndsAtOffsetAdjuster: WorklistDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: WorklistDigest, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class PercentWorklistDigestAdjuster: WorklistDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleWorklistDigestAdjuster: WorklistDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: WorklistDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the worklist digest steps in order and keeps a trace of each.
    final class WorklistDigestEngine {
        var steps: [any WorklistDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WorklistDigest) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [WorklistDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWorklistDigestEngine() -> WorklistDigestEngine {
        return WorklistDigestEngine(
            steps: [
                RoundingWorklistDigestAdjuster(step: 1.0),
                TieredWorklistDigestAdjuster(bounds: [443.0, 2498.0, 6603.0], rates: [0.84, 0.89, 1.11]),
                WorklistDigestEndsAtOffsetAdjuster(weight: 0.78),
                PercentWorklistDigestAdjuster(percent: 1.7),
                TitleWorklistDigestAdjuster(factors: ["south": 0.75]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 20498.5
        )
    }
}
