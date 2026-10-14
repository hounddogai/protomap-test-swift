import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional handoff cycle calculation.
    protocol RegionalHandoffCycleModifier {
        func describe() -> String
        func adjust(_ item: RegionalHandoffCycle, value: Double) -> Double
    }

    final class CapRegionalHandoffCycleAdjuster: RegionalHandoffCycleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalHandoffCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleRegionalHandoffCycleAdjuster: RegionalHandoffCycleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalHandoffCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRegionalHandoffCycleAdjuster: RegionalHandoffCycleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalHandoffCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalHandoffCycleAdjuster: RegionalHandoffCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalHandoffCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionalHandoffCycleCreatedAtOffsetAdjuster: RegionalHandoffCycleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: RegionalHandoffCycle, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    /// Runs the regional handoff cycle steps in order and keeps a trace of each.
    final class RegionalHandoffCycleEngine {
        var steps: [any RegionalHandoffCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalHandoffCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalHandoffCycle) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [RegionalHandoffCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalHandoffCycleEngine() -> RegionalHandoffCycleEngine {
        return RegionalHandoffCycleEngine(
            steps: [
                CapRegionalHandoffCycleAdjuster(cap: 3036.0),
                TitleRegionalHandoffCycleAdjuster(factors: ["west": 1.1, "retail": 0.94]),
                PercentRegionalHandoffCycleAdjuster(percent: 1.3),
                MinimumRegionalHandoffCycleAdjuster(minimum: 8.0),
                RegionalHandoffCycleCreatedAtOffsetAdjuster(weight: 1.3),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 19846.3
        )
    }
}
