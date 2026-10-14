import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global program claim calculation.
    protocol GlobalProgramClaimFactor {
        func describe() -> String
        func adjust(_ item: GlobalProgramClaim, value: Double) -> Double
    }

    final class LocaleGlobalProgramClaimAdjuster: GlobalProgramClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: GlobalProgramClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumGlobalProgramClaimAdjuster: GlobalProgramClaimFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalProgramClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingGlobalProgramClaimAdjuster: GlobalProgramClaimFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalProgramClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class GlobalProgramClaimDosageMgOffsetAdjuster: GlobalProgramClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: GlobalProgramClaim, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class PercentGlobalProgramClaimAdjuster: GlobalProgramClaimFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalProgramClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalProgramClaimAdjuster: GlobalProgramClaimFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalProgramClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global program claim steps in order and keeps a trace of each.
    final class GlobalProgramClaimEngine {
        var steps: [any GlobalProgramClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalProgramClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalProgramClaim) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [GlobalProgramClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalProgramClaimEngine() -> GlobalProgramClaimEngine {
        return GlobalProgramClaimEngine(
            steps: [
                LocaleGlobalProgramClaimAdjuster(factors: ["east": 1.11]),
                MinimumGlobalProgramClaimAdjuster(minimum: 37.7),
                RoundingGlobalProgramClaimAdjuster(step: 5.0),
                GlobalProgramClaimDosageMgOffsetAdjuster(weight: 1.64),
                PercentGlobalProgramClaimAdjuster(percent: -8.0),
                CapGlobalProgramClaimAdjuster(cap: 1930.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 33313.1
        )
    }
}
