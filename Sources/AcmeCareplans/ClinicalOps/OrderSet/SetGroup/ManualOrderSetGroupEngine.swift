import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the manual order set group calculation.
    protocol ManualOrderSetGroupStep {
        func describe() -> String
        func adjust(_ item: ManualOrderSetGroup, value: Double) -> Double
    }

    final class MinimumManualOrderSetGroupAdjuster: ManualOrderSetGroupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualOrderSetGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameManualOrderSetGroupAdjuster: ManualOrderSetGroupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ManualOrderSetGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapManualOrderSetGroupAdjuster: ManualOrderSetGroupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualOrderSetGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ManualOrderSetGroupEndsAtOffsetAdjuster: ManualOrderSetGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: ManualOrderSetGroup, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class PercentManualOrderSetGroupAdjuster: ManualOrderSetGroupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualOrderSetGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual order set group steps in order and keeps a trace of each.
    final class ManualOrderSetGroupEngine {
        var steps: [any ManualOrderSetGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualOrderSetGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualOrderSetGroup) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualOrderSetGroupStep = steps[index]
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

        func evaluateAll(_ items: [ManualOrderSetGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualOrderSetGroupEngine() -> ManualOrderSetGroupEngine {
        return ManualOrderSetGroupEngine(
            steps: [
                MinimumManualOrderSetGroupAdjuster(minimum: 19.5),
                NameManualOrderSetGroupAdjuster(factors: ["west": 1.34, "north": 1.17, "central": 1.28]),
                CapManualOrderSetGroupAdjuster(cap: 25210.0),
                ManualOrderSetGroupEndsAtOffsetAdjuster(weight: 0.7),
                PercentManualOrderSetGroupAdjuster(percent: 5.3),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 58521.4
        )
    }
}
