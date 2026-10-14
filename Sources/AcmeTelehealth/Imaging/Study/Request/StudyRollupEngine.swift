import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study rollup calculation.
    protocol StudyRollupAdjuster {
        func describe() -> String
        func adjust(_ item: StudyRollup, value: Double) -> Double
    }

    final class StudyRollupThresholdOffsetAdjuster: StudyRollupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: StudyRollup, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class FlaggedStudyRollupAdjuster: StudyRollupAdjuster {
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

        func adjust(_ item: StudyRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelStudyRollupAdjuster: StudyRollupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: StudyRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredStudyRollupAdjuster: StudyRollupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapStudyRollupAdjuster: StudyRollupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the study rollup steps in order and keeps a trace of each.
    final class StudyRollupEngine {
        var steps: [any StudyRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StudyRollup) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [StudyRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStudyRollupEngine(_ flags: Kit.Flags.Registry) -> StudyRollupEngine {
        return StudyRollupEngine(
            steps: [
                StudyRollupThresholdOffsetAdjuster(weight: 0.25),
                FlaggedStudyRollupAdjuster(flags: flags, flag: "study-rollup-default", percent: 7.3),
                ChannelStudyRollupAdjuster(factors: ["central": 1.36]),
                TieredStudyRollupAdjuster(bounds: [1651.0, 6681.0], rates: [1.17, 0.9]),
                CapStudyRollupAdjuster(cap: 5879.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 29177.8
        )
    }
}
