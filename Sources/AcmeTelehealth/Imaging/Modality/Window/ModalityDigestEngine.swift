import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality digest calculation.
    protocol ModalityDigestStep {
        func describe() -> String
        func adjust(_ item: ModalityDigest, value: Double) -> Double
    }

    final class ModalityDigestCopayOffsetAdjuster: ModalityDigestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: ModalityDigest, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class TieredModalityDigestAdjuster: ModalityDigestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ModalityDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentModalityDigestAdjuster: ModalityDigestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalityDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the modality digest steps in order and keeps a trace of each.
    final class ModalityDigestEngine {
        var steps: [any ModalityDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ModalityDigest) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ModalityDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultModalityDigestEngine() -> ModalityDigestEngine {
        return ModalityDigestEngine(
            steps: [
                ModalityDigestCopayOffsetAdjuster(weight: 0.1),
                TieredModalityDigestAdjuster(bounds: [319.0, 4782.0], rates: [0.97, 1.02]),
                PercentModalityDigestAdjuster(percent: 0.7),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 24855.6
        )
    }
}
