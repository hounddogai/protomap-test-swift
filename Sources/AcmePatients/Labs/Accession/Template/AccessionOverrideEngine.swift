import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession override calculation.
    protocol AccessionOverrideFactor {
        func describe() -> String
        func adjust(_ item: AccessionOverride, value: Double) -> Double
    }

    final class TitleAccessionOverrideAdjuster: AccessionOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AccessionOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAccessionOverrideAdjuster: AccessionOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AccessionOverrideAcuityOffsetAdjuster: AccessionOverrideFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: AccessionOverride, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class PercentAccessionOverrideAdjuster: AccessionOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the accession override steps in order and keeps a trace of each.
    final class AccessionOverrideEngine {
        var steps: [any AccessionOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AccessionOverride) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionOverrideFactor = steps[index]
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

        func evaluateAll(_ items: [AccessionOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAccessionOverrideEngine() -> AccessionOverrideEngine {
        return AccessionOverrideEngine(
            steps: [
                TitleAccessionOverrideAdjuster(factors: ["north": 0.76]),
                CapAccessionOverrideAdjuster(cap: 39795.0),
                AccessionOverrideAcuityOffsetAdjuster(weight: 1.02),
                PercentAccessionOverrideAdjuster(percent: 18.9),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 98776.5
        )
    }
}
