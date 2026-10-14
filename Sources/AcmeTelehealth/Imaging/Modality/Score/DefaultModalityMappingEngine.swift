import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the default modality mapping calculation.
    protocol DefaultModalityMappingAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultModalityMapping, value: Double) -> Double
    }

    final class FlaggedDefaultModalityMappingAdjuster: DefaultModalityMappingAdjuster {
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

        func adjust(_ item: DefaultModalityMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultModalityMappingAdjuster: DefaultModalityMappingAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultModalityMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDefaultModalityMappingAdjuster: DefaultModalityMappingAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultModalityMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default modality mapping steps in order and keeps a trace of each.
    final class DefaultModalityMappingEngine {
        var steps: [any DefaultModalityMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultModalityMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultModalityMapping) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultModalityMappingAdjuster = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [DefaultModalityMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultModalityMappingEngine(_ flags: Kit.Flags.Registry) -> DefaultModalityMappingEngine {
        return DefaultModalityMappingEngine(
            steps: [
                FlaggedDefaultModalityMappingAdjuster(
                    flags: flags,
                    flag: "default-modality-mapping-pending",
                    percent: -9.7
                ),
                TieredDefaultModalityMappingAdjuster(
                    bounds: [966.0, 5294.0, 7914.0, 8757.0],
                    rates: [1.08, 0.8, 0.82, 0.99]
                ),
                CapDefaultModalityMappingAdjuster(cap: 45602.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 65437.1
        )
    }
}
