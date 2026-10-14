import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen notice calculation.
    protocol SpecimenNoticeModifier {
        func describe() -> String
        func adjust(_ item: SpecimenNotice, value: Double) -> Double
    }

    final class FlaggedSpecimenNoticeAdjuster: SpecimenNoticeModifier {
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

        func adjust(_ item: SpecimenNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSpecimenNoticeAdjuster: SpecimenNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SpecimenNoticeRateOffsetAdjuster: SpecimenNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: SpecimenNotice, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class PercentSpecimenNoticeAdjuster: SpecimenNoticeModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SpecimenNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSpecimenNoticeAdjuster: SpecimenNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSpecimenNoticeAdjuster: SpecimenNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the specimen notice steps in order and keeps a trace of each.
    final class SpecimenNoticeEngine {
        var steps: [any SpecimenNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SpecimenNotice) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [SpecimenNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSpecimenNoticeEngine(_ flags: Kit.Flags.Registry) -> SpecimenNoticeEngine {
        return SpecimenNoticeEngine(
            steps: [
                FlaggedSpecimenNoticeAdjuster(flags: flags, flag: "specimen-notice-default", percent: -3.7),
                TieredSpecimenNoticeAdjuster(bounds: [164.0, 2820.0, 3556.0], rates: [0.85, 0.86, 1.12]),
                SpecimenNoticeRateOffsetAdjuster(weight: 0.39),
                PercentSpecimenNoticeAdjuster(percent: 3.9),
                CapSpecimenNoticeAdjuster(cap: 22981.0),
                MinimumSpecimenNoticeAdjuster(minimum: 6.1),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 29026.4
        )
    }
}
