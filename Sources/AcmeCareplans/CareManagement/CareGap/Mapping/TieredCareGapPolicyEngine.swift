import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered care gap policy calculation.
    protocol TieredCareGapPolicyStep {
        func describe() -> String
        func adjust(_ item: TieredCareGapPolicy, value: Double) -> Double
    }

    final class TieredCareGapPolicyMinimumOffsetAdjuster: TieredCareGapPolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: TieredCareGapPolicy, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class MinimumTieredCareGapPolicyAdjuster: TieredCareGapPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredCareGapPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingTieredCareGapPolicyAdjuster: TieredCareGapPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredCareGapPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameTieredCareGapPolicyAdjuster: TieredCareGapPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TieredCareGapPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentTieredCareGapPolicyAdjuster: TieredCareGapPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredCareGapPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredCareGapPolicyAdjuster: TieredCareGapPolicyStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredCareGapPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered care gap policy steps in order and keeps a trace of each.
    final class TieredCareGapPolicyEngine {
        var steps: [any TieredCareGapPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredCareGapPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredCareGapPolicy) -> Double {
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

        func evaluateAll(_ items: [TieredCareGapPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredCareGapPolicyEngine() -> TieredCareGapPolicyEngine {
        return TieredCareGapPolicyEngine(
            steps: [
                TieredCareGapPolicyMinimumOffsetAdjuster(weight: 1.01),
                MinimumTieredCareGapPolicyAdjuster(minimum: 21.4),
                RoundingTieredCareGapPolicyAdjuster(step: 0.1),
                NameTieredCareGapPolicyAdjuster(factors: ["online": 0.93]),
                PercentTieredCareGapPolicyAdjuster(percent: 6.7),
                CapTieredCareGapPolicyAdjuster(cap: 37630.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 70730.9
        )
    }
}
