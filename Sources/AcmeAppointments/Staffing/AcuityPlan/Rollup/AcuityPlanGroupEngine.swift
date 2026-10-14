import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan group calculation.
    protocol AcuityPlanGroupFactor {
        func describe() -> String
        func adjust(_ item: AcuityPlanGroup, value: Double) -> Double
    }

    final class CapAcuityPlanGroupAdjuster: AcuityPlanGroupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAcuityPlanGroupAdjuster: AcuityPlanGroupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAcuityPlanGroupAdjuster: AcuityPlanGroupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AcuityPlanGroupWindowDaysOffsetAdjuster: AcuityPlanGroupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: AcuityPlanGroup, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class RoundingAcuityPlanGroupAdjuster: AcuityPlanGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAcuityPlanGroupAdjuster: AcuityPlanGroupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the acuity plan group steps in order and keeps a trace of each.
    final class AcuityPlanGroupEngine {
        var steps: [any AcuityPlanGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AcuityPlanGroup) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [AcuityPlanGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanGroupEngine() -> AcuityPlanGroupEngine {
        return AcuityPlanGroupEngine(
            steps: [
                CapAcuityPlanGroupAdjuster(cap: 48591.0),
                TieredAcuityPlanGroupAdjuster(
                    bounds: [1075.0, 2836.0, 2950.0, 7423.0],
                    rates: [0.87, 0.92, 0.84, 0.9]
                ),
                PercentAcuityPlanGroupAdjuster(percent: 15.5),
                AcuityPlanGroupWindowDaysOffsetAdjuster(weight: 0.66),
                RoundingAcuityPlanGroupAdjuster(step: 0.1),
                MinimumAcuityPlanGroupAdjuster(minimum: 15.6),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 52155.6
        )
    }
}
