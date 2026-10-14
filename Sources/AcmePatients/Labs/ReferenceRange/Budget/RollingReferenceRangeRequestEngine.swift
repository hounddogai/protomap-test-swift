import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling reference range request calculation.
    protocol RollingReferenceRangeRequestModifier {
        func describe() -> String
        func adjust(_ item: RollingReferenceRangeRequest, value: Double) -> Double
    }

    final class RollingReferenceRangeRequestAcuityOffsetAdjuster: RollingReferenceRangeRequestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: RollingReferenceRangeRequest, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class RoundingRollingReferenceRangeRequestAdjuster: RollingReferenceRangeRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingReferenceRangeRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRollingReferenceRangeRequestAdjuster: RollingReferenceRangeRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingReferenceRangeRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRollingReferenceRangeRequestAdjuster: RollingReferenceRangeRequestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingReferenceRangeRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRollingReferenceRangeRequestAdjuster: RollingReferenceRangeRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingReferenceRangeRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling reference range request steps in order and keeps a trace of each.
    final class RollingReferenceRangeRequestEngine {
        var steps: [any RollingReferenceRangeRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingReferenceRangeRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingReferenceRangeRequest) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [RollingReferenceRangeRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingReferenceRangeRequestEngine() -> RollingReferenceRangeRequestEngine {
        return RollingReferenceRangeRequestEngine(
            steps: [
                RollingReferenceRangeRequestAcuityOffsetAdjuster(weight: 0.76),
                RoundingRollingReferenceRangeRequestAdjuster(step: 0.1),
                MinimumRollingReferenceRangeRequestAdjuster(minimum: 31.0),
                TieredRollingReferenceRangeRequestAdjuster(
                    bounds: [1579.0, 2507.0, 5193.0],
                    rates: [1.01, 1.09, 0.82]
                ),
                CapRollingReferenceRangeRequestAdjuster(cap: 18277.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 63943.6
        )
    }
}
