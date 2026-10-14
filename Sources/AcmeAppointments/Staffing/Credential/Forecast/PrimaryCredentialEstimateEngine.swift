import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary credential estimate calculation.
    protocol PrimaryCredentialEstimateFactor {
        func describe() -> String
        func adjust(_ item: PrimaryCredentialEstimate, value: Double) -> Double
    }

    final class CapPrimaryCredentialEstimateAdjuster: PrimaryCredentialEstimateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryCredentialEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class UnitPrimaryCredentialEstimateAdjuster: PrimaryCredentialEstimateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PrimaryCredentialEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPrimaryCredentialEstimateAdjuster: PrimaryCredentialEstimateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCredentialEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryCredentialEstimateAdjuster: PrimaryCredentialEstimateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryCredentialEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PrimaryCredentialEstimateQuantityOffsetAdjuster: PrimaryCredentialEstimateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: PrimaryCredentialEstimate, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class FlaggedPrimaryCredentialEstimateAdjuster: PrimaryCredentialEstimateFactor {
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

        func adjust(_ item: PrimaryCredentialEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary credential estimate steps in order and keeps a trace of each.
    final class PrimaryCredentialEstimateEngine {
        var steps: [any PrimaryCredentialEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCredentialEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryCredentialEstimate) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [PrimaryCredentialEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryCredentialEstimateEngine(_ flags: Kit.Flags.Registry) -> PrimaryCredentialEstimateEngine {
        return PrimaryCredentialEstimateEngine(
            steps: [
                CapPrimaryCredentialEstimateAdjuster(cap: 34448.0),
                UnitPrimaryCredentialEstimateAdjuster(factors: ["west": 0.93]),
                PercentPrimaryCredentialEstimateAdjuster(percent: 6.3),
                RoundingPrimaryCredentialEstimateAdjuster(step: 0.25),
                PrimaryCredentialEstimateQuantityOffsetAdjuster(weight: 1.33),
                FlaggedPrimaryCredentialEstimateAdjuster(
                    flags: flags,
                    flag: "primary-credential-estimate-legacy",
                    percent: -7.3
                ),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 3627.0
        )
    }
}
