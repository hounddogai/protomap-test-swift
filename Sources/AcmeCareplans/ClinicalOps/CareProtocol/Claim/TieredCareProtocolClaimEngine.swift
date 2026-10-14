import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the tiered care protocol claim calculation.
    protocol TieredCareProtocolClaimFactor {
        func describe() -> String
        func adjust(_ item: TieredCareProtocolClaim, value: Double) -> Double
    }

    final class TieredTieredCareProtocolClaimAdjuster: TieredCareProtocolClaimFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredCareProtocolClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumTieredCareProtocolClaimAdjuster: TieredCareProtocolClaimFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredCareProtocolClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCareProtocolClaimAcuityOffsetAdjuster: TieredCareProtocolClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: TieredCareProtocolClaim, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the tiered care protocol claim steps in order and keeps a trace of each.
    final class TieredCareProtocolClaimEngine {
        var steps: [any TieredCareProtocolClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredCareProtocolClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredCareProtocolClaim) -> Double {
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

        func evaluateAll(_ items: [TieredCareProtocolClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredCareProtocolClaimEngine() -> TieredCareProtocolClaimEngine {
        return TieredCareProtocolClaimEngine(
            steps: [
                TieredTieredCareProtocolClaimAdjuster(
                    bounds: [3920.0, 6660.0, 9148.0, 9427.0],
                    rates: [1.13, 1.04, 1.0, 1.17]
                ),
                MinimumTieredCareProtocolClaimAdjuster(minimum: 26.6),
                TieredCareProtocolClaimAcuityOffsetAdjuster(weight: 1.92),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 20823.9
        )
    }
}
