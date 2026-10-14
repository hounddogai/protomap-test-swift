import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary worklist notice calculation.
    protocol PrimaryWorklistNoticeFactor {
        func describe() -> String
        func adjust(_ item: PrimaryWorklistNotice, value: Double) -> Double
    }

    final class FlaggedPrimaryWorklistNoticeAdjuster: PrimaryWorklistNoticeFactor {
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

        func adjust(_ item: PrimaryWorklistNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryWorklistNoticeAdjuster: PrimaryWorklistNoticeFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryWorklistNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPrimaryWorklistNoticeAdjuster: PrimaryWorklistNoticeFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryWorklistNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryWorklistNoticeAdjuster: PrimaryWorklistNoticeFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryWorklistNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary worklist notice steps in order and keeps a trace of each.
    final class PrimaryWorklistNoticeEngine {
        var steps: [any PrimaryWorklistNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryWorklistNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryWorklistNotice) -> Double {
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

        func evaluateAll(_ items: [PrimaryWorklistNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryWorklistNoticeEngine(_ flags: Kit.Flags.Registry) -> PrimaryWorklistNoticeEngine {
        return PrimaryWorklistNoticeEngine(
            steps: [
                FlaggedPrimaryWorklistNoticeAdjuster(
                    flags: flags,
                    flag: "primary-worklist-notice-regional",
                    percent: 3.0
                ),
                CapPrimaryWorklistNoticeAdjuster(cap: 17549.0),
                PercentPrimaryWorklistNoticeAdjuster(percent: 17.6),
                TieredPrimaryWorklistNoticeAdjuster(bounds: [939.0, 1828.0], rates: [0.96, 1.0]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 21606.1
        )
    }
}
