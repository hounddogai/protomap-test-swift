import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered remittance request calculation.
    protocol TieredRemittanceRequestModifier {
        func describe() -> String
        func adjust(_ item: TieredRemittanceRequest, value: Double) -> Double
    }

    final class PercentTieredRemittanceRequestAdjuster: TieredRemittanceRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredRemittanceRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionTieredRemittanceRequestAdjuster: TieredRemittanceRequestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: TieredRemittanceRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTieredRemittanceRequestAdjuster: TieredRemittanceRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredRemittanceRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered remittance request steps in order and keeps a trace of each.
    final class TieredRemittanceRequestEngine {
        var steps: [any TieredRemittanceRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRemittanceRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredRemittanceRequest) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [TieredRemittanceRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredRemittanceRequestEngine() -> TieredRemittanceRequestEngine {
        return TieredRemittanceRequestEngine(
            steps: [
                PercentTieredRemittanceRequestAdjuster(percent: -9.5),
                RegionTieredRemittanceRequestAdjuster(factors: ["retail": 0.81, "north": 1.05, "west": 1.18]),
                MinimumTieredRemittanceRequestAdjuster(minimum: 35.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 48903.2
        )
    }
}
