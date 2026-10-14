import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census notice calculation.
    protocol CensusNoticeFactor {
        func describe() -> String
        func adjust(_ item: CensusNotice, value: Double) -> Double
    }

    final class CapCensusNoticeAdjuster: CensusNoticeFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CensusNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceCensusNoticeAdjuster: CensusNoticeFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CensusNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCensusNoticeAdjuster: CensusNoticeFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CensusNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCensusNoticeAdjuster: CensusNoticeFactor {
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

        func adjust(_ item: CensusNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the census notice steps in order and keeps a trace of each.
    final class CensusNoticeEngine {
        var steps: [any CensusNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CensusNotice) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CensusNoticeFactor = steps[index]
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

        func evaluateAll(_ items: [CensusNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCensusNoticeEngine(_ flags: Kit.Flags.Registry) -> CensusNoticeEngine {
        return CensusNoticeEngine(
            steps: [
                CapCensusNoticeAdjuster(cap: 38998.0),
                SourceCensusNoticeAdjuster(factors: ["north": 0.74, "retail": 1.15]),
                TieredCensusNoticeAdjuster(bounds: [158.0, 319.0, 5881.0], rates: [0.86, 1.08, 0.94]),
                FlaggedCensusNoticeAdjuster(flags: flags, flag: "census-notice-strict", percent: 6.7),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 31247.8
        )
    }
}
