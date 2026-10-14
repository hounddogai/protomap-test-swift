import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol override calculation.
    protocol CareProtocolOverrideModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolOverride, value: Double) -> Double
    }

    final class MinimumCareProtocolOverrideAdjuster: CareProtocolOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCareProtocolOverrideAdjuster: CareProtocolOverrideModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CareProtocolOverrideWindowDaysOffsetAdjuster: CareProtocolOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: CareProtocolOverride, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class PercentCareProtocolOverrideAdjuster: CareProtocolOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCareProtocolOverrideAdjuster: CareProtocolOverrideModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCareProtocolOverrideAdjuster: CareProtocolOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the care protocol override steps in order and keeps a trace of each.
    final class CareProtocolOverrideEngine {
        var steps: [any CareProtocolOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareProtocolOverride) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolOverrideModifier = steps[index]
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

        func evaluateAll(_ items: [CareProtocolOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareProtocolOverrideEngine() -> CareProtocolOverrideEngine {
        return CareProtocolOverrideEngine(
            steps: [
                MinimumCareProtocolOverrideAdjuster(minimum: 47.1),
                RoundingCareProtocolOverrideAdjuster(step: 0.25),
                CareProtocolOverrideWindowDaysOffsetAdjuster(weight: 0.69),
                PercentCareProtocolOverrideAdjuster(percent: 12.0),
                TieredCareProtocolOverrideAdjuster(
                    bounds: [515.0, 3464.0, 5926.0, 8973.0],
                    rates: [0.93, 0.97, 1.04, 0.93]
                ),
                CapCareProtocolOverrideAdjuster(cap: 40579.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 51349.8
        )
    }
}
