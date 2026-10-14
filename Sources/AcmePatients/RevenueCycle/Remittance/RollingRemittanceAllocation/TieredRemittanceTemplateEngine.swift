import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered remittance template calculation.
    protocol TieredRemittanceTemplateFactor {
        func describe() -> String
        func adjust(_ item: TieredRemittanceTemplate, value: Double) -> Double
    }

    final class CapTieredRemittanceTemplateAdjuster: TieredRemittanceTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredRemittanceTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredTieredRemittanceTemplateAdjuster: TieredRemittanceTemplateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredRemittanceTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentTieredRemittanceTemplateAdjuster: TieredRemittanceTemplateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredRemittanceTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRemittanceTemplateExpiresAtOffsetAdjuster: TieredRemittanceTemplateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: TieredRemittanceTemplate, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class MinimumTieredRemittanceTemplateAdjuster: TieredRemittanceTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredRemittanceTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered remittance template steps in order and keeps a trace of each.
    final class TieredRemittanceTemplateEngine {
        var steps: [any TieredRemittanceTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRemittanceTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredRemittanceTemplate) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredRemittanceTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [TieredRemittanceTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredRemittanceTemplateEngine() -> TieredRemittanceTemplateEngine {
        return TieredRemittanceTemplateEngine(
            steps: [
                CapTieredRemittanceTemplateAdjuster(cap: 32953.0),
                TieredTieredRemittanceTemplateAdjuster(bounds: [1256.0, 5224.0, 6065.0], rates: [1.05, 0.81, 0.82]),
                PercentTieredRemittanceTemplateAdjuster(percent: -1.6),
                TieredRemittanceTemplateExpiresAtOffsetAdjuster(weight: 0.69),
                MinimumTieredRemittanceTemplateAdjuster(minimum: 28.1),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 26315.4
        )
    }
}
