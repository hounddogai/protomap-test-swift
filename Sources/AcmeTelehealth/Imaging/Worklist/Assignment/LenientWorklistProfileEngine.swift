import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the lenient worklist profile calculation.
    protocol LenientWorklistProfileFactor {
        func describe() -> String
        func adjust(_ item: LenientWorklistProfile, value: Double) -> Double
    }

    final class LenientWorklistProfileScoreOffsetAdjuster: LenientWorklistProfileFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: LenientWorklistProfile, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class SourceLenientWorklistProfileAdjuster: LenientWorklistProfileFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: LenientWorklistProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedLenientWorklistProfileAdjuster: LenientWorklistProfileFactor {
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

        func adjust(_ item: LenientWorklistProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientWorklistProfileAdjuster: LenientWorklistProfileFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientWorklistProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLenientWorklistProfileAdjuster: LenientWorklistProfileFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientWorklistProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientWorklistProfileAdjuster: LenientWorklistProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientWorklistProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient worklist profile steps in order and keeps a trace of each.
    final class LenientWorklistProfileEngine {
        var steps: [any LenientWorklistProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientWorklistProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientWorklistProfile) -> Double {
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

        func evaluateAll(_ items: [LenientWorklistProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientWorklistProfileEngine(_ flags: Kit.Flags.Registry) -> LenientWorklistProfileEngine {
        return LenientWorklistProfileEngine(
            steps: [
                LenientWorklistProfileScoreOffsetAdjuster(weight: 1.52),
                SourceLenientWorklistProfileAdjuster(factors: ["online": 1.28, "west": 1.39]),
                FlaggedLenientWorklistProfileAdjuster(
                    flags: flags,
                    flag: "lenient-worklist-profile-rolling",
                    percent: 8.0
                ),
                CapLenientWorklistProfileAdjuster(cap: 10709.0),
                PercentLenientWorklistProfileAdjuster(percent: -11.7),
                MinimumLenientWorklistProfileAdjuster(minimum: 36.1),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 92314.8
        )
    }
}
