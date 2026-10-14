import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped slot profile calculation.
    protocol CappedSlotProfileModifier {
        func describe() -> String
        func adjust(_ item: CappedSlotProfile, value: Double) -> Double
    }

    final class MinimumCappedSlotProfileAdjuster: CappedSlotProfileModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedSlotProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCappedSlotProfileAdjuster: CappedSlotProfileModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedSlotProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCappedSlotProfileAdjuster: CappedSlotProfileModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedSlotProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped slot profile steps in order and keeps a trace of each.
    final class CappedSlotProfileEngine {
        var steps: [any CappedSlotProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedSlotProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedSlotProfile) -> Double {
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

        func evaluateAll(_ items: [CappedSlotProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedSlotProfileEngine() -> CappedSlotProfileEngine {
        return CappedSlotProfileEngine(
            steps: [
                MinimumCappedSlotProfileAdjuster(minimum: 15.2),
                CapCappedSlotProfileAdjuster(cap: 7447.0),
                PercentCappedSlotProfileAdjuster(percent: -12.6),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 11213.3
        )
    }
}
