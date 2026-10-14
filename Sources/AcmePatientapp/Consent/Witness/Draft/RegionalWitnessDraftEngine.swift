import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional witness draft calculation.
    protocol RegionalWitnessDraftModifier {
        func describe() -> String
        func adjust(_ item: RegionalWitnessDraft, value: Double) -> Double
    }

    final class RoundingRegionalWitnessDraftAdjuster: RegionalWitnessDraftModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalWitnessDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionalWitnessDraftBatchSizeOffsetAdjuster: RegionalWitnessDraftModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: RegionalWitnessDraft, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class CapRegionalWitnessDraftAdjuster: RegionalWitnessDraftModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalWitnessDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRegionalWitnessDraftAdjuster: RegionalWitnessDraftModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalWitnessDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional witness draft steps in order and keeps a trace of each.
    final class RegionalWitnessDraftEngine {
        var steps: [any RegionalWitnessDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalWitnessDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalWitnessDraft) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [RegionalWitnessDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalWitnessDraftEngine() -> RegionalWitnessDraftEngine {
        return RegionalWitnessDraftEngine(
            steps: [
                RoundingRegionalWitnessDraftAdjuster(step: 0.05),
                RegionalWitnessDraftBatchSizeOffsetAdjuster(weight: 1.82),
                CapRegionalWitnessDraftAdjuster(cap: 31252.0),
                TieredRegionalWitnessDraftAdjuster(bounds: [258.0, 566.0, 6973.0], rates: [0.93, 1.2, 1.14]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 25268.4
        )
    }
}
