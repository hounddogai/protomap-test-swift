import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual formulary digest calculation.
    protocol ManualFormularyDigestFactor {
        func describe() -> String
        func adjust(_ item: ManualFormularyDigest, value: Double) -> Double
    }

    final class MinimumManualFormularyDigestAdjuster: ManualFormularyDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualFormularyDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapManualFormularyDigestAdjuster: ManualFormularyDigestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualFormularyDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingManualFormularyDigestAdjuster: ManualFormularyDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualFormularyDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualFormularyDigestAdjuster: ManualFormularyDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualFormularyDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual formulary digest steps in order and keeps a trace of each.
    final class ManualFormularyDigestEngine {
        var steps: [any ManualFormularyDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualFormularyDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualFormularyDigest) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [ManualFormularyDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualFormularyDigestEngine() -> ManualFormularyDigestEngine {
        return ManualFormularyDigestEngine(
            steps: [
                MinimumManualFormularyDigestAdjuster(minimum: 30.1),
                CapManualFormularyDigestAdjuster(cap: 47741.0),
                RoundingManualFormularyDigestAdjuster(step: 0.1),
                TieredManualFormularyDigestAdjuster(bounds: [1663.0, 8598.0], rates: [1.18, 1.05]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 23993.0
        )
    }
}
