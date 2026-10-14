import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped care protocol score calculation.
    protocol CappedCareProtocolScoreModifier {
        func describe() -> String
        func adjust(_ item: CappedCareProtocolScore, value: Double) -> Double
    }

    final class TitleCappedCareProtocolScoreAdjuster: CappedCareProtocolScoreModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CappedCareProtocolScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCappedCareProtocolScoreAdjuster: CappedCareProtocolScoreModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedCareProtocolScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCappedCareProtocolScoreAdjuster: CappedCareProtocolScoreModifier {
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

        func adjust(_ item: CappedCareProtocolScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedCareProtocolScoreAdjuster: CappedCareProtocolScoreModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedCareProtocolScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCappedCareProtocolScoreAdjuster: CappedCareProtocolScoreModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedCareProtocolScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped care protocol score steps in order and keeps a trace of each.
    final class CappedCareProtocolScoreEngine {
        var steps: [any CappedCareProtocolScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCareProtocolScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedCareProtocolScore) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [CappedCareProtocolScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedCareProtocolScoreEngine(_ flags: Kit.Flags.Registry) -> CappedCareProtocolScoreEngine {
        return CappedCareProtocolScoreEngine(
            steps: [
                TitleCappedCareProtocolScoreAdjuster(factors: ["retail": 1.08, "west": 0.85, "online": 1.2]),
                TieredCappedCareProtocolScoreAdjuster(bounds: [6786.0, 9115.0, 9645.0], rates: [1.11, 1.05, 0.9]),
                FlaggedCappedCareProtocolScoreAdjuster(
                    flags: flags,
                    flag: "capped-care-protocol-score-weighted",
                    percent: 2.0
                ),
                CapCappedCareProtocolScoreAdjuster(cap: 26012.0),
                RoundingCappedCareProtocolScoreAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 62857.6
        )
    }
}
