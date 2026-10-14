import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol variance calculation.
    protocol CareProtocolVarianceStep {
        func describe() -> String
        func adjust(_ item: CareProtocolVariance, value: Double) -> Double
    }

    final class RoundingCareProtocolVarianceAdjuster: CareProtocolVarianceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCareProtocolVarianceAdjuster: CareProtocolVarianceStep {
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

    final class CareProtocolVarianceFloorValueOffsetAdjuster: CareProtocolVarianceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: CareProtocolVariance, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class CapCareProtocolVarianceAdjuster: CareProtocolVarianceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCareProtocolVarianceAdjuster: CareProtocolVarianceStep {
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

    /// Runs the care protocol variance steps in order and keeps a trace of each.
    final class CareProtocolVarianceEngine {
        var steps: [any CareProtocolVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolVariance) -> Double {
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

        func evaluateAll(_ items: [CareProtocolVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolVarianceEngine() -> CareProtocolVarianceEngine {
        return CareProtocolVarianceEngine(
            steps: [
                RoundingCareProtocolVarianceAdjuster(step: 0.5),
                TieredCareProtocolVarianceAdjuster(
                    bounds: [4669.0, 6533.0, 8743.0, 9553.0],
                    rates: [0.84, 1.05, 1.18, 1.05]
                ),
                CareProtocolVarianceFloorValueOffsetAdjuster(weight: 1.72),
                CapCareProtocolVarianceAdjuster(cap: 44829.0),
                MinimumCareProtocolVarianceAdjuster(minimum: 15.7),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 1426.6
        )
    }
}
