import AcmePlatform
import Foundation

extension Consent {
    /// One step of the manual language claim calculation.
    protocol ManualLanguageClaimModifier {
        func describe() -> String
        func adjust(_ item: ManualLanguageClaim, value: Double) -> Double
    }

    final class TieredManualLanguageClaimAdjuster: ManualLanguageClaimModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualLanguageClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ManualLanguageClaimEndsAtOffsetAdjuster: ManualLanguageClaimModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: ManualLanguageClaim, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class CapManualLanguageClaimAdjuster: ManualLanguageClaimModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualLanguageClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual language claim steps in order and keeps a trace of each.
    final class ManualLanguageClaimEngine {
        var steps: [any ManualLanguageClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualLanguageClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualLanguageClaim) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [ManualLanguageClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualLanguageClaimEngine() -> ManualLanguageClaimEngine {
        return ManualLanguageClaimEngine(
            steps: [
                TieredManualLanguageClaimAdjuster(
                    bounds: [346.0, 1536.0, 5730.0, 9647.0],
                    rates: [1.06, 1.07, 0.85, 1.08]
                ),
                ManualLanguageClaimEndsAtOffsetAdjuster(weight: 1.65),
                CapManualLanguageClaimAdjuster(cap: 12828.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 84582.6
        )
    }
}
