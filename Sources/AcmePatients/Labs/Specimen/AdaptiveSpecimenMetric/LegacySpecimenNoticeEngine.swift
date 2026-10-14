import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy specimen notice calculation.
    protocol LegacySpecimenNoticeFactor {
        func describe() -> String
        func adjust(_ item: LegacySpecimenNotice, value: Double) -> Double
    }

    final class CapLegacySpecimenNoticeAdjuster: LegacySpecimenNoticeFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacySpecimenNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLegacySpecimenNoticeAdjuster: LegacySpecimenNoticeFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacySpecimenNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLegacySpecimenNoticeAdjuster: LegacySpecimenNoticeFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacySpecimenNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryLegacySpecimenNoticeAdjuster: LegacySpecimenNoticeFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: LegacySpecimenNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy specimen notice steps in order and keeps a trace of each.
    final class LegacySpecimenNoticeEngine {
        var steps: [any LegacySpecimenNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacySpecimenNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacySpecimenNotice) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacySpecimenNoticeFactor = steps[index]
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

        func evaluateAll(_ items: [LegacySpecimenNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacySpecimenNoticeEngine() -> LegacySpecimenNoticeEngine {
        return LegacySpecimenNoticeEngine(
            steps: [
                CapLegacySpecimenNoticeAdjuster(cap: 7403.0),
                PercentLegacySpecimenNoticeAdjuster(percent: -17.9),
                MinimumLegacySpecimenNoticeAdjuster(minimum: 7.3),
                CategoryLegacySpecimenNoticeAdjuster(factors: ["online": 0.85]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 51107.8
        )
    }
}
