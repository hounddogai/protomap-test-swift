import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall digest calculation.
    protocol RecallDigestFactor {
        func describe() -> String
        func adjust(_ item: RecallDigest, value: Double) -> Double
    }

    final class FlaggedRecallDigestAdjuster: RecallDigestFactor {
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

        func adjust(_ item: RecallDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleRecallDigestAdjuster: RecallDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RecallDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRecallDigestAdjuster: RecallDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRecallDigestAdjuster: RecallDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the recall digest steps in order and keeps a trace of each.
    final class RecallDigestEngine {
        var steps: [any RecallDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RecallDigest) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [RecallDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRecallDigestEngine(_ flags: Kit.Flags.Registry) -> RecallDigestEngine {
        return RecallDigestEngine(
            steps: [
                FlaggedRecallDigestAdjuster(flags: flags, flag: "recall-digest-seasonal", percent: -4.4),
                TitleRecallDigestAdjuster(factors: ["central": 1.19, "west": 1.08, "online": 1.05]),
                TieredRecallDigestAdjuster(bounds: [3444.0, 3784.0, 7798.0], rates: [0.88, 1.05, 0.8]),
                PercentRecallDigestAdjuster(percent: -23.9),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 81034.7
        )
    }
}
