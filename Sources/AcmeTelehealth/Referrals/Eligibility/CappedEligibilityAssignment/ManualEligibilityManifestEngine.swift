import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual eligibility manifest calculation.
    protocol ManualEligibilityManifestStep {
        func describe() -> String
        func adjust(_ item: ManualEligibilityManifest, value: Double) -> Double
    }

    final class WardManualEligibilityManifestAdjuster: ManualEligibilityManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: ManualEligibilityManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredManualEligibilityManifestAdjuster: ManualEligibilityManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualEligibilityManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ManualEligibilityManifestAmountOffsetAdjuster: ManualEligibilityManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: ManualEligibilityManifest, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class CapManualEligibilityManifestAdjuster: ManualEligibilityManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualEligibilityManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingManualEligibilityManifestAdjuster: ManualEligibilityManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualEligibilityManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual eligibility manifest steps in order and keeps a trace of each.
    final class ManualEligibilityManifestEngine {
        var steps: [any ManualEligibilityManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualEligibilityManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualEligibilityManifest) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualEligibilityManifestStep = steps[index]
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

        func evaluateAll(_ items: [ManualEligibilityManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualEligibilityManifestEngine() -> ManualEligibilityManifestEngine {
        return ManualEligibilityManifestEngine(
            steps: [
                WardManualEligibilityManifestAdjuster(factors: ["central": 1.23, "south": 1.13]),
                TieredManualEligibilityManifestAdjuster(
                    bounds: [74.0, 779.0, 6140.0, 6628.0],
                    rates: [0.98, 0.92, 0.95, 1.1]
                ),
                ManualEligibilityManifestAmountOffsetAdjuster(weight: 1.05),
                CapManualEligibilityManifestAdjuster(cap: 1124.0),
                RoundingManualEligibilityManifestAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 43479.2
        )
    }
}
