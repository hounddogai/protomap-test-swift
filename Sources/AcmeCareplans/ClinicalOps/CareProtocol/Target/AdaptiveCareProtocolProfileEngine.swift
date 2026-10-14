import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the adaptive care protocol profile calculation.
    protocol AdaptiveCareProtocolProfileModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveCareProtocolProfile, value: Double) -> Double
    }

    final class CapAdaptiveCareProtocolProfileAdjuster: AdaptiveCareProtocolProfileModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveCareProtocolProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAdaptiveCareProtocolProfileAdjuster: AdaptiveCareProtocolProfileModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveCareProtocolProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAdaptiveCareProtocolProfileAdjuster: AdaptiveCareProtocolProfileModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveCareProtocolProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive care protocol profile steps in order and keeps a trace of each.
    final class AdaptiveCareProtocolProfileEngine {
        var steps: [any AdaptiveCareProtocolProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveCareProtocolProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveCareProtocolProfile) -> Double {
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

        func evaluateAll(_ items: [AdaptiveCareProtocolProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveCareProtocolProfileEngine() -> AdaptiveCareProtocolProfileEngine {
        return AdaptiveCareProtocolProfileEngine(
            steps: [
                CapAdaptiveCareProtocolProfileAdjuster(cap: 2434.0),
                PercentAdaptiveCareProtocolProfileAdjuster(percent: 12.7),
                MinimumAdaptiveCareProtocolProfileAdjuster(minimum: 27.9),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 98239.5
        )
    }
}
