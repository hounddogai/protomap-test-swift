import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped program claim calculation.
    protocol CappedProgramClaimFactor {
        func describe() -> String
        func adjust(_ item: CappedProgramClaim, value: Double) -> Double
    }

    final class CappedProgramClaimQuantityOffsetAdjuster: CappedProgramClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: CappedProgramClaim, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CapCappedProgramClaimAdjuster: CappedProgramClaimFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedProgramClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedProgramClaimAdjuster: CappedProgramClaimFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedProgramClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionCappedProgramClaimAdjuster: CappedProgramClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: CappedProgramClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the capped program claim steps in order and keeps a trace of each.
    final class CappedProgramClaimEngine {
        var steps: [any CappedProgramClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedProgramClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedProgramClaim) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedProgramClaimFactor = steps[index]
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

        func evaluateAll(_ items: [CappedProgramClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedProgramClaimEngine() -> CappedProgramClaimEngine {
        return CappedProgramClaimEngine(
            steps: [
                CappedProgramClaimQuantityOffsetAdjuster(weight: 0.9),
                CapCappedProgramClaimAdjuster(cap: 26179.0),
                TieredCappedProgramClaimAdjuster(bounds: [735.0, 3718.0, 7458.0], rates: [1.08, 0.99, 0.85]),
                RegionCappedProgramClaimAdjuster(factors: ["west": 0.88, "east": 0.81, "online": 1.03]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 68864.5
        )
    }
}
