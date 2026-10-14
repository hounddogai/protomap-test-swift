import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered revocation template calculation.
    protocol TieredRevocationTemplateModifier {
        func describe() -> String
        func adjust(_ item: TieredRevocationTemplate, value: Double) -> Double
    }

    final class CapTieredRevocationTemplateAdjuster: TieredRevocationTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredRevocationTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredTieredRevocationTemplateAdjuster: TieredRevocationTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredRevocationTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumTieredRevocationTemplateAdjuster: TieredRevocationTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredRevocationTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered revocation template steps in order and keeps a trace of each.
    final class TieredRevocationTemplateEngine {
        var steps: [any TieredRevocationTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRevocationTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredRevocationTemplate) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredRevocationTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [TieredRevocationTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredRevocationTemplateEngine() -> TieredRevocationTemplateEngine {
        return TieredRevocationTemplateEngine(
            steps: [
                CapTieredRevocationTemplateAdjuster(cap: 4621.0),
                TieredTieredRevocationTemplateAdjuster(bounds: [10.0, 1643.0, 7926.0], rates: [1.0, 1.18, 1.08]),
                MinimumTieredRevocationTemplateAdjuster(minimum: 17.4),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 63779.6
        )
    }
}
