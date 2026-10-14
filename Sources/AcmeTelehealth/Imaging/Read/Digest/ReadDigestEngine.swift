import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read digest calculation.
    protocol ReadDigestFactor {
        func describe() -> String
        func adjust(_ item: ReadDigest, value: Double) -> Double
    }

    final class FlaggedReadDigestAdjuster: ReadDigestFactor {
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

        func adjust(_ item: ReadDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingReadDigestAdjuster: ReadDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ReadDigestRateOffsetAdjuster: ReadDigestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: ReadDigest, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class NameReadDigestAdjuster: ReadDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ReadDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the read digest steps in order and keeps a trace of each.
    final class ReadDigestEngine {
        var steps: [any ReadDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReadDigest) -> Double {
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

        func evaluateAll(_ items: [ReadDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReadDigestEngine(_ flags: Kit.Flags.Registry) -> ReadDigestEngine {
        return ReadDigestEngine(
            steps: [
                FlaggedReadDigestAdjuster(flags: flags, flag: "read-digest-capped", percent: -5.7),
                RoundingReadDigestAdjuster(step: 1.0),
                ReadDigestRateOffsetAdjuster(weight: 0.29),
                NameReadDigestAdjuster(factors: ["south": 1.37]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 35148.1
        )
    }
}
