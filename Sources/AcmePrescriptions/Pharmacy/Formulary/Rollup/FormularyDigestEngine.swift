import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary digest calculation.
    protocol FormularyDigestAdjuster {
        func describe() -> String
        func adjust(_ item: FormularyDigest, value: Double) -> Double
    }

    final class PercentFormularyDigestAdjuster: FormularyDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFormularyDigestAdjuster: FormularyDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularyDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedFormularyDigestAdjuster: FormularyDigestAdjuster {
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

        func adjust(_ item: FormularyDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFormularyDigestAdjuster: FormularyDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SegmentFormularyDigestAdjuster: FormularyDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: FormularyDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the formulary digest steps in order and keeps a trace of each.
    final class FormularyDigestEngine {
        var steps: [any FormularyDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FormularyDigest) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [FormularyDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFormularyDigestEngine(_ flags: Kit.Flags.Registry) -> FormularyDigestEngine {
        return FormularyDigestEngine(
            steps: [
                PercentFormularyDigestAdjuster(percent: -19.2),
                MinimumFormularyDigestAdjuster(minimum: 25.9),
                FlaggedFormularyDigestAdjuster(flags: flags, flag: "formulary-digest-global", percent: -4.9),
                CapFormularyDigestAdjuster(cap: 48681.0),
                SegmentFormularyDigestAdjuster(factors: ["central": 1.4, "south": 1.31]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 95728.6
        )
    }
}
