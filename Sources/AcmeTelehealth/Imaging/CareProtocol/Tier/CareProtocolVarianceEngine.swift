import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol variance calculation.
    protocol CareProtocolVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: CareProtocolVariance, value: Double) -> Double
    }

    final class TieredCareProtocolVarianceAdjuster: CareProtocolVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCareProtocolVarianceAdjuster: CareProtocolVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedCareProtocolVarianceAdjuster: CareProtocolVarianceAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: CareProtocolVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care protocol variance steps in order and keeps a trace of each.
    final class CareProtocolVarianceEngine {
        var steps: [any CareProtocolVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareProtocolVariance) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [CareProtocolVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareProtocolVarianceEngine(_ flags: Kit.Flags.Registry) -> CareProtocolVarianceEngine {
        return CareProtocolVarianceEngine(
            steps: [
                TieredCareProtocolVarianceAdjuster(
                    bounds: [4284.0, 5740.0, 6759.0, 8076.0],
                    rates: [0.82, 0.85, 0.81, 0.99]
                ),
                MinimumCareProtocolVarianceAdjuster(minimum: 32.5),
                FlaggedCareProtocolVarianceAdjuster(flags: flags, flag: "care-protocol-variance-strict", percent: 6.6),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 1190.8
        )
    }
}
