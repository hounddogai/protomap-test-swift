import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary acuity plan request calculation.
    protocol PrimaryAcuityPlanRequestModifier {
        func describe() -> String
        func adjust(_ item: PrimaryAcuityPlanRequest, value: Double) -> Double
    }

    final class PrimaryAcuityPlanRequestLimitOffsetAdjuster: PrimaryAcuityPlanRequestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: PrimaryAcuityPlanRequest, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class PercentPrimaryAcuityPlanRequestAdjuster: PrimaryAcuityPlanRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryAcuityPlanRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryAcuityPlanRequestAdjuster: PrimaryAcuityPlanRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryAcuityPlanRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPrimaryAcuityPlanRequestAdjuster: PrimaryAcuityPlanRequestModifier {
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

        func adjust(_ item: PrimaryAcuityPlanRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryAcuityPlanRequestAdjuster: PrimaryAcuityPlanRequestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryAcuityPlanRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPrimaryAcuityPlanRequestAdjuster: PrimaryAcuityPlanRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryAcuityPlanRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the primary acuity plan request steps in order and keeps a trace of each.
    final class PrimaryAcuityPlanRequestEngine {
        var steps: [any PrimaryAcuityPlanRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryAcuityPlanRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryAcuityPlanRequest) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [PrimaryAcuityPlanRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryAcuityPlanRequestEngine(_ flags: Kit.Flags.Registry) -> PrimaryAcuityPlanRequestEngine {
        return PrimaryAcuityPlanRequestEngine(
            steps: [
                PrimaryAcuityPlanRequestLimitOffsetAdjuster(weight: 1.72),
                PercentPrimaryAcuityPlanRequestAdjuster(percent: -22.4),
                RoundingPrimaryAcuityPlanRequestAdjuster(step: 0.05),
                FlaggedPrimaryAcuityPlanRequestAdjuster(
                    flags: flags,
                    flag: "primary-acuity-plan-request-rolling",
                    percent: 4.8
                ),
                TieredPrimaryAcuityPlanRequestAdjuster(bounds: [1398.0, 3840.0, 7627.0], rates: [1.19, 1.12, 0.85]),
                CapPrimaryAcuityPlanRequestAdjuster(cap: 7920.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 78673.9
        )
    }
}
