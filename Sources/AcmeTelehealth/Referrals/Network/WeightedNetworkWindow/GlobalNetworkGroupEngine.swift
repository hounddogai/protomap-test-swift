import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global network group calculation.
    protocol GlobalNetworkGroupModifier {
        func describe() -> String
        func adjust(_ item: GlobalNetworkGroup, value: Double) -> Double
    }

    final class RoundingGlobalNetworkGroupAdjuster: GlobalNetworkGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalNetworkGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FacilityGlobalNetworkGroupAdjuster: GlobalNetworkGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: GlobalNetworkGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGlobalNetworkGroupAdjuster: GlobalNetworkGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalNetworkGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class GlobalNetworkGroupRevisionOffsetAdjuster: GlobalNetworkGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: GlobalNetworkGroup, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class CapGlobalNetworkGroupAdjuster: GlobalNetworkGroupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalNetworkGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global network group steps in order and keeps a trace of each.
    final class GlobalNetworkGroupEngine {
        var steps: [any GlobalNetworkGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalNetworkGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalNetworkGroup) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalNetworkGroupModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalNetworkGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalNetworkGroupEngine() -> GlobalNetworkGroupEngine {
        return GlobalNetworkGroupEngine(
            steps: [
                RoundingGlobalNetworkGroupAdjuster(step: 0.25),
                FacilityGlobalNetworkGroupAdjuster(factors: ["west": 0.97]),
                TieredGlobalNetworkGroupAdjuster(bounds: [1763.0, 3787.0, 6744.0], rates: [0.81, 1.1, 1.1]),
                GlobalNetworkGroupRevisionOffsetAdjuster(weight: 1.88),
                CapGlobalNetworkGroupAdjuster(cap: 27155.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 44870.9
        )
    }
}
