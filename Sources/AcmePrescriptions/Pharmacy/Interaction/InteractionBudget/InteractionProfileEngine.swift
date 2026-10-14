import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction profile calculation.
    protocol InteractionProfileModifier {
        func describe() -> String
        func adjust(_ item: InteractionProfile, value: Double) -> Double
    }

    final class InteractionProfilePriorityOffsetAdjuster: InteractionProfileModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: InteractionProfile, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class FlaggedInteractionProfileAdjuster: InteractionProfileModifier {
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

        func adjust(_ item: InteractionProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredInteractionProfileAdjuster: InteractionProfileModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingInteractionProfileAdjuster: InteractionProfileModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the interaction profile steps in order and keeps a trace of each.
    final class InteractionProfileEngine {
        var steps: [any InteractionProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InteractionProfile) -> Double {
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

        func evaluateAll(_ items: [InteractionProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInteractionProfileEngine(_ flags: Kit.Flags.Registry) -> InteractionProfileEngine {
        return InteractionProfileEngine(
            steps: [
                InteractionProfilePriorityOffsetAdjuster(weight: 1.67),
                FlaggedInteractionProfileAdjuster(flags: flags, flag: "interaction-profile-scheduled", percent: -8.5),
                TieredInteractionProfileAdjuster(
                    bounds: [4462.0, 6003.0, 7218.0, 9036.0],
                    rates: [0.83, 0.83, 1.04, 1.17]
                ),
                RoundingInteractionProfileAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 98764.7
        )
    }
}
