import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal care protocol policy calculation.
    protocol SeasonalCareProtocolPolicyStep {
        func describe() -> String
        func adjust(_ item: SeasonalCareProtocolPolicy, value: Double) -> Double
    }

    final class SeasonalCareProtocolPolicyWindowDaysOffsetAdjuster: SeasonalCareProtocolPolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: SeasonalCareProtocolPolicy, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class FacilitySeasonalCareProtocolPolicyAdjuster: SeasonalCareProtocolPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: SeasonalCareProtocolPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSeasonalCareProtocolPolicyAdjuster: SeasonalCareProtocolPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalCareProtocolPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal care protocol policy steps in order and keeps a trace of each.
    final class SeasonalCareProtocolPolicyEngine {
        var steps: [any SeasonalCareProtocolPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCareProtocolPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalCareProtocolPolicy) -> Double {
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

        func evaluateAll(_ items: [SeasonalCareProtocolPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalCareProtocolPolicyEngine() -> SeasonalCareProtocolPolicyEngine {
        return SeasonalCareProtocolPolicyEngine(
            steps: [
                SeasonalCareProtocolPolicyWindowDaysOffsetAdjuster(weight: 0.79),
                FacilitySeasonalCareProtocolPolicyAdjuster(factors: ["east": 0.78, "north": 1.3]),
                MinimumSeasonalCareProtocolPolicyAdjuster(minimum: 32.8),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 6916.4
        )
    }
}
