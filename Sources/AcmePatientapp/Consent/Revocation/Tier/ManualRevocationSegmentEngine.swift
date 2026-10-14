import AcmePlatform
import Foundation

extension Consent {
    /// One step of the manual revocation segment calculation.
    protocol ManualRevocationSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: ManualRevocationSegment, value: Double) -> Double
    }

    final class CapManualRevocationSegmentAdjuster: ManualRevocationSegmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualRevocationSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedManualRevocationSegmentAdjuster: ManualRevocationSegmentAdjuster {
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

        func adjust(_ item: ManualRevocationSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualRevocationSegmentWindowDaysOffsetAdjuster: ManualRevocationSegmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: ManualRevocationSegment, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class MinimumManualRevocationSegmentAdjuster: ManualRevocationSegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualRevocationSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualRevocationSegmentAdjuster: ManualRevocationSegmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualRevocationSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualRevocationSegmentAdjuster: ManualRevocationSegmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualRevocationSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual revocation segment steps in order and keeps a trace of each.
    final class ManualRevocationSegmentEngine {
        var steps: [any ManualRevocationSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRevocationSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualRevocationSegment) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualRevocationSegmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualRevocationSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualRevocationSegmentEngine(_ flags: Kit.Flags.Registry) -> ManualRevocationSegmentEngine {
        return ManualRevocationSegmentEngine(
            steps: [
                CapManualRevocationSegmentAdjuster(cap: 49293.0),
                FlaggedManualRevocationSegmentAdjuster(
                    flags: flags,
                    flag: "manual-revocation-segment-tiered",
                    percent: -3.1
                ),
                ManualRevocationSegmentWindowDaysOffsetAdjuster(weight: 1.23),
                MinimumManualRevocationSegmentAdjuster(minimum: 35.4),
                PercentManualRevocationSegmentAdjuster(percent: -5.1),
                TieredManualRevocationSegmentAdjuster(bounds: [3054.0, 4708.0, 5599.0], rates: [1.05, 1.03, 0.89]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 37329.5
        )
    }
}
