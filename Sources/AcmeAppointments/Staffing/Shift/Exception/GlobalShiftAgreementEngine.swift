import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global shift agreement calculation.
    protocol GlobalShiftAgreementStep {
        func describe() -> String
        func adjust(_ item: GlobalShiftAgreement, value: Double) -> Double
    }

    final class TieredGlobalShiftAgreementAdjuster: GlobalShiftAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalShiftAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedGlobalShiftAgreementAdjuster: GlobalShiftAgreementStep {
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

        func adjust(_ item: GlobalShiftAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalShiftAgreementAdjuster: GlobalShiftAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalShiftAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitGlobalShiftAgreementAdjuster: GlobalShiftAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: GlobalShiftAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GlobalShiftAgreementSequenceOffsetAdjuster: GlobalShiftAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: GlobalShiftAgreement, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class PercentGlobalShiftAgreementAdjuster: GlobalShiftAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalShiftAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global shift agreement steps in order and keeps a trace of each.
    final class GlobalShiftAgreementEngine {
        var steps: [any GlobalShiftAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalShiftAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalShiftAgreement) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalShiftAgreementStep = steps[index]
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

        func evaluateAll(_ items: [GlobalShiftAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalShiftAgreementEngine(_ flags: Kit.Flags.Registry) -> GlobalShiftAgreementEngine {
        return GlobalShiftAgreementEngine(
            steps: [
                TieredGlobalShiftAgreementAdjuster(bounds: [206.0, 500.0, 6968.0], rates: [0.86, 1.12, 1.02]),
                FlaggedGlobalShiftAgreementAdjuster(
                    flags: flags,
                    flag: "global-shift-agreement-legacy",
                    percent: -1.3
                ),
                RoundingGlobalShiftAgreementAdjuster(step: 0.05),
                UnitGlobalShiftAgreementAdjuster(factors: ["north": 0.98, "online": 1.38, "south": 1.0]),
                GlobalShiftAgreementSequenceOffsetAdjuster(weight: 0.74),
                PercentGlobalShiftAgreementAdjuster(percent: 22.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 99480.2
        )
    }
}
