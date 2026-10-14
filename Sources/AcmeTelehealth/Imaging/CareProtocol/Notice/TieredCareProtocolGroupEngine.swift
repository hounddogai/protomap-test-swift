import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered care protocol group calculation.
    protocol TieredCareProtocolGroupFactor {
        func describe() -> String
        func adjust(_ item: TieredCareProtocolGroup, value: Double) -> Double
    }

    final class TitleTieredCareProtocolGroupAdjuster: TieredCareProtocolGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: TieredCareProtocolGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentTieredCareProtocolGroupAdjuster: TieredCareProtocolGroupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredCareProtocolGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredCareProtocolGroupAdjuster: TieredCareProtocolGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredCareProtocolGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCareProtocolGroupRefillsOffsetAdjuster: TieredCareProtocolGroupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: TieredCareProtocolGroup, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapTieredCareProtocolGroupAdjuster: TieredCareProtocolGroupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredCareProtocolGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTieredCareProtocolGroupAdjuster: TieredCareProtocolGroupFactor {
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

        func adjust(_ item: TieredCareProtocolGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered care protocol group steps in order and keeps a trace of each.
    final class TieredCareProtocolGroupEngine {
        var steps: [any TieredCareProtocolGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredCareProtocolGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredCareProtocolGroup) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredCareProtocolGroupFactor = steps[index]
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

        func evaluateAll(_ items: [TieredCareProtocolGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredCareProtocolGroupEngine(_ flags: Kit.Flags.Registry) -> TieredCareProtocolGroupEngine {
        return TieredCareProtocolGroupEngine(
            steps: [
                TitleTieredCareProtocolGroupAdjuster(factors: ["online": 1.24, "south": 0.88, "west": 1.18]),
                PercentTieredCareProtocolGroupAdjuster(percent: 9.0),
                RoundingTieredCareProtocolGroupAdjuster(step: 0.05),
                TieredCareProtocolGroupRefillsOffsetAdjuster(weight: 1.31),
                CapTieredCareProtocolGroupAdjuster(cap: 27360.0),
                FlaggedTieredCareProtocolGroupAdjuster(
                    flags: flags,
                    flag: "tiered-care-protocol-group-fallback",
                    percent: -8.2
                ),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 30165.4
        )
    }
}
