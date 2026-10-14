import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy result request calculation.
    protocol LegacyResultRequestModifier {
        func describe() -> String
        func adjust(_ item: LegacyResultRequest, value: Double) -> Double
    }

    final class CapLegacyResultRequestAdjuster: LegacyResultRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyResultRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLegacyResultRequestAdjuster: LegacyResultRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyResultRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLegacyResultRequestAdjuster: LegacyResultRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyResultRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy result request steps in order and keeps a trace of each.
    final class LegacyResultRequestEngine {
        var steps: [any LegacyResultRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyResultRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyResultRequest) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyResultRequestModifier = steps[index]
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

        func evaluateAll(_ items: [LegacyResultRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyResultRequestEngine() -> LegacyResultRequestEngine {
        return LegacyResultRequestEngine(
            steps: [
                CapLegacyResultRequestAdjuster(cap: 5779.0),
                PercentLegacyResultRequestAdjuster(percent: 21.6),
                MinimumLegacyResultRequestAdjuster(minimum: 29.9),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 11239.0
        )
    }
}
