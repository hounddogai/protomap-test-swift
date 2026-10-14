import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive modality request calculation.
    protocol AdaptiveModalityRequestFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveModalityRequest, value: Double) -> Double
    }

    final class TieredAdaptiveModalityRequestAdjuster: AdaptiveModalityRequestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveModalityRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameAdaptiveModalityRequestAdjuster: AdaptiveModalityRequestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AdaptiveModalityRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAdaptiveModalityRequestAdjuster: AdaptiveModalityRequestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveModalityRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive modality request steps in order and keeps a trace of each.
    final class AdaptiveModalityRequestEngine {
        var steps: [any AdaptiveModalityRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveModalityRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveModalityRequest) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [AdaptiveModalityRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveModalityRequestEngine() -> AdaptiveModalityRequestEngine {
        return AdaptiveModalityRequestEngine(
            steps: [
                TieredAdaptiveModalityRequestAdjuster(bounds: [3052.0, 9554.0, 9905.0], rates: [0.97, 1.18, 1.15]),
                NameAdaptiveModalityRequestAdjuster(factors: ["east": 1.05]),
                CapAdaptiveModalityRequestAdjuster(cap: 11324.0),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 87032.1
        )
    }
}
