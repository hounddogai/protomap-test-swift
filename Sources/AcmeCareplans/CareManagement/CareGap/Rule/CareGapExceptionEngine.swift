import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap exception calculation.
    protocol CareGapExceptionModifier {
        func describe() -> String
        func adjust(_ item: CareGapException, value: Double) -> Double
    }

    final class CapCareGapExceptionAdjuster: CareGapExceptionModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceCareGapExceptionAdjuster: CareGapExceptionModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CareGapException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCareGapExceptionAdjuster: CareGapExceptionModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CareGapExceptionVersionOffsetAdjuster: CareGapExceptionModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: CareGapException, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    /// Runs the care gap exception steps in order and keeps a trace of each.
    final class CareGapExceptionEngine {
        var steps: [any CareGapExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareGapException) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapExceptionModifier = steps[index]
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

        func evaluateAll(_ items: [CareGapException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareGapExceptionEngine() -> CareGapExceptionEngine {
        return CareGapExceptionEngine(
            steps: [
                CapCareGapExceptionAdjuster(cap: 23365.0),
                SourceCareGapExceptionAdjuster(factors: ["south": 1.0]),
                PercentCareGapExceptionAdjuster(percent: -14.0),
                CareGapExceptionVersionOffsetAdjuster(weight: 0.02),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 14349.4
        )
    }
}
