import AcmePlatform
import Foundation

extension Labs {
    /// One step of the manual result baseline calculation.
    protocol ManualResultBaselineStep {
        func describe() -> String
        func adjust(_ item: ManualResultBaseline, value: Double) -> Double
    }

    final class ManualResultBaselineBatchSizeOffsetAdjuster: ManualResultBaselineStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ManualResultBaseline, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class CapManualResultBaselineAdjuster: ManualResultBaselineStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualResultBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedManualResultBaselineAdjuster: ManualResultBaselineStep {
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

        func adjust(_ item: ManualResultBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentManualResultBaselineAdjuster: ManualResultBaselineStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualResultBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualResultBaselineAdjuster: ManualResultBaselineStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualResultBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LocaleManualResultBaselineAdjuster: ManualResultBaselineStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ManualResultBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the manual result baseline steps in order and keeps a trace of each.
    final class ManualResultBaselineEngine {
        var steps: [any ManualResultBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualResultBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualResultBaseline) -> Double {
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

        func evaluateAll(_ items: [ManualResultBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualResultBaselineEngine(_ flags: Kit.Flags.Registry) -> ManualResultBaselineEngine {
        return ManualResultBaselineEngine(
            steps: [
                ManualResultBaselineBatchSizeOffsetAdjuster(weight: 1.16),
                CapManualResultBaselineAdjuster(cap: 25090.0),
                FlaggedManualResultBaselineAdjuster(
                    flags: flags,
                    flag: "manual-result-baseline-pending",
                    percent: -0.9
                ),
                PercentManualResultBaselineAdjuster(percent: -15.8),
                TieredManualResultBaselineAdjuster(bounds: [862.0, 4727.0], rates: [1.03, 1.12]),
                LocaleManualResultBaselineAdjuster(factors: ["east": 1.35]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 41941.8
        )
    }
}
