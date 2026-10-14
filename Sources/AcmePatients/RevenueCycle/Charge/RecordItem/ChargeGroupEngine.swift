import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge group calculation.
    protocol ChargeGroupFactor {
        func describe() -> String
        func adjust(_ item: ChargeGroup, value: Double) -> Double
    }

    final class ChargeGroupWindowDaysOffsetAdjuster: ChargeGroupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: ChargeGroup, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class CapChargeGroupAdjuster: ChargeGroupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceChargeGroupAdjuster: ChargeGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ChargeGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentChargeGroupAdjuster: ChargeGroupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge group steps in order and keeps a trace of each.
    final class ChargeGroupEngine {
        var steps: [any ChargeGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ChargeGroup) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [ChargeGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultChargeGroupEngine() -> ChargeGroupEngine {
        return ChargeGroupEngine(
            steps: [
                ChargeGroupWindowDaysOffsetAdjuster(weight: 0.65),
                CapChargeGroupAdjuster(cap: 43267.0),
                SourceChargeGroupAdjuster(factors: ["east": 1.0, "retail": 0.98, "north": 1.32]),
                PercentChargeGroupAdjuster(percent: -20.8),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 8064.1
        )
    }
}
