import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol allocation calculation.
    protocol CareProtocolAllocationModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolAllocation, value: Double) -> Double
    }

    final class RoundingCareProtocolAllocationAdjuster: CareProtocolAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameCareProtocolAllocationAdjuster: CareProtocolAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CareProtocolAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCareProtocolAllocationAdjuster: CareProtocolAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care protocol allocation steps in order and keeps a trace of each.
    final class CareProtocolAllocationEngine {
        var steps: [any CareProtocolAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareProtocolAllocation) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [CareProtocolAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareProtocolAllocationEngine() -> CareProtocolAllocationEngine {
        return CareProtocolAllocationEngine(
            steps: [
                RoundingCareProtocolAllocationAdjuster(step: 1.0),
                NameCareProtocolAllocationAdjuster(factors: ["east": 1.12, "online": 1.28, "west": 1.3]),
                PercentCareProtocolAllocationAdjuster(percent: 5.7),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 94143.7
        )
    }
}
