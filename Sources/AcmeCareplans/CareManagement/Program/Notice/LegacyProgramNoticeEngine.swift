import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the legacy program notice calculation.
    protocol LegacyProgramNoticeFactor {
        func describe() -> String
        func adjust(_ item: LegacyProgramNotice, value: Double) -> Double
    }

    final class MinimumLegacyProgramNoticeAdjuster: LegacyProgramNoticeFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyProgramNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelLegacyProgramNoticeAdjuster: LegacyProgramNoticeFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LegacyProgramNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapLegacyProgramNoticeAdjuster: LegacyProgramNoticeFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyProgramNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLegacyProgramNoticeAdjuster: LegacyProgramNoticeFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyProgramNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyProgramNoticeAdjuster: LegacyProgramNoticeFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyProgramNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy program notice steps in order and keeps a trace of each.
    final class LegacyProgramNoticeEngine {
        var steps: [any LegacyProgramNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyProgramNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyProgramNotice) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [LegacyProgramNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyProgramNoticeEngine() -> LegacyProgramNoticeEngine {
        return LegacyProgramNoticeEngine(
            steps: [
                MinimumLegacyProgramNoticeAdjuster(minimum: 44.6),
                LabelLegacyProgramNoticeAdjuster(factors: ["east": 1.03, "south": 1.3]),
                CapLegacyProgramNoticeAdjuster(cap: 38107.0),
                PercentLegacyProgramNoticeAdjuster(percent: 2.6),
                RoundingLegacyProgramNoticeAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 93722.3
        )
    }
}
