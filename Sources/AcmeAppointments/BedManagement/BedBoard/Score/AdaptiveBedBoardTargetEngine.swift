import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the adaptive bed board target calculation.
    protocol AdaptiveBedBoardTargetFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveBedBoardTarget, value: Double) -> Double
    }

    final class CapAdaptiveBedBoardTargetAdjuster: AdaptiveBedBoardTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveBedBoardTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAdaptiveBedBoardTargetAdjuster: AdaptiveBedBoardTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveBedBoardTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveBedBoardTargetAdjuster: AdaptiveBedBoardTargetFactor {
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

        func adjust(_ item: AdaptiveBedBoardTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveBedBoardTargetAdjuster: AdaptiveBedBoardTargetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveBedBoardTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AdaptiveBedBoardTargetCreatedAtOffsetAdjuster: AdaptiveBedBoardTargetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: AdaptiveBedBoardTarget, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    /// Runs the adaptive bed board target steps in order and keeps a trace of each.
    final class AdaptiveBedBoardTargetEngine {
        var steps: [any AdaptiveBedBoardTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveBedBoardTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveBedBoardTarget) -> Double {
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

        func evaluateAll(_ items: [AdaptiveBedBoardTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveBedBoardTargetEngine(_ flags: Kit.Flags.Registry) -> AdaptiveBedBoardTargetEngine {
        return AdaptiveBedBoardTargetEngine(
            steps: [
                CapAdaptiveBedBoardTargetAdjuster(cap: 30697.0),
                PercentAdaptiveBedBoardTargetAdjuster(percent: -23.8),
                FlaggedAdaptiveBedBoardTargetAdjuster(
                    flags: flags,
                    flag: "adaptive-bed-board-target-regional",
                    percent: -7.8
                ),
                TieredAdaptiveBedBoardTargetAdjuster(
                    bounds: [719.0, 5661.0, 6495.0, 7514.0],
                    rates: [0.98, 0.82, 0.8, 1.08]
                ),
                AdaptiveBedBoardTargetCreatedAtOffsetAdjuster(weight: 1.09),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 70992.3
        )
    }
}
