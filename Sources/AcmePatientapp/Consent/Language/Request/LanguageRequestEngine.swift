import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language request calculation.
    protocol LanguageRequestModifier {
        func describe() -> String
        func adjust(_ item: LanguageRequest, value: Double) -> Double
    }

    final class RoundingLanguageRequestAdjuster: LanguageRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguageRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLanguageRequestAdjuster: LanguageRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLanguageRequestAdjuster: LanguageRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryLanguageRequestAdjuster: LanguageRequestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: LanguageRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLanguageRequestAdjuster: LanguageRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLanguageRequestAdjuster: LanguageRequestModifier {
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

        func adjust(_ item: LanguageRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the language request steps in order and keeps a trace of each.
    final class LanguageRequestEngine {
        var steps: [any LanguageRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LanguageRequest) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [LanguageRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLanguageRequestEngine(_ flags: Kit.Flags.Registry) -> LanguageRequestEngine {
        return LanguageRequestEngine(
            steps: [
                RoundingLanguageRequestAdjuster(step: 5.0),
                PercentLanguageRequestAdjuster(percent: 3.2),
                CapLanguageRequestAdjuster(cap: 12626.0),
                CountryLanguageRequestAdjuster(factors: ["central": 1.35, "west": 1.0, "south": 0.74]),
                MinimumLanguageRequestAdjuster(minimum: 19.4),
                FlaggedLanguageRequestAdjuster(flags: flags, flag: "language-request-pending", percent: 4.2),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 64385.4
        )
    }
}
