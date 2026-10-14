import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read draft calculation.
    protocol ReadDraftAdjuster {
        func describe() -> String
        func adjust(_ item: ReadDraft, value: Double) -> Double
    }

    final class CapReadDraftAdjuster: ReadDraftAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredReadDraftAdjuster: ReadDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingReadDraftAdjuster: ReadDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedReadDraftAdjuster: ReadDraftAdjuster {
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

        func adjust(_ item: ReadDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumReadDraftAdjuster: ReadDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReadDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentReadDraftAdjuster: ReadDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the read draft steps in order and keeps a trace of each.
    final class ReadDraftEngine {
        var steps: [any ReadDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReadDraft) -> Double {
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

        func evaluateAll(_ items: [ReadDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReadDraftEngine(_ flags: Kit.Flags.Registry) -> ReadDraftEngine {
        return ReadDraftEngine(
            steps: [
                CapReadDraftAdjuster(cap: 4498.0),
                TieredReadDraftAdjuster(bounds: [5387.0, 8385.0], rates: [0.8, 1.07]),
                RoundingReadDraftAdjuster(step: 5.0),
                FlaggedReadDraftAdjuster(flags: flags, flag: "read-draft-batched", percent: 9.4),
                MinimumReadDraftAdjuster(minimum: 31.0),
                PercentReadDraftAdjuster(percent: 12.9),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 21950.1
        )
    }
}
