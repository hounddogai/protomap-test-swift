import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the lenient follow up mapping calculation.
    protocol LenientFollowUpMappingModifier {
        func describe() -> String
        func adjust(_ item: LenientFollowUpMapping, value: Double) -> Double
    }

    final class MinimumLenientFollowUpMappingAdjuster: LenientFollowUpMappingModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientFollowUpMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLenientFollowUpMappingAdjuster: LenientFollowUpMappingModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientFollowUpMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LenientFollowUpMappingWindowDaysOffsetAdjuster: LenientFollowUpMappingModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: LenientFollowUpMapping, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class CapLenientFollowUpMappingAdjuster: LenientFollowUpMappingModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientFollowUpMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient follow up mapping steps in order and keeps a trace of each.
    final class LenientFollowUpMappingEngine {
        var steps: [any LenientFollowUpMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientFollowUpMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientFollowUpMapping) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientFollowUpMappingModifier = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [LenientFollowUpMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientFollowUpMappingEngine() -> LenientFollowUpMappingEngine {
        return LenientFollowUpMappingEngine(
            steps: [
                MinimumLenientFollowUpMappingAdjuster(minimum: 27.7),
                RoundingLenientFollowUpMappingAdjuster(step: 0.1),
                LenientFollowUpMappingWindowDaysOffsetAdjuster(weight: 0.51),
                CapLenientFollowUpMappingAdjuster(cap: 46427.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 67797.2
        )
    }
}
