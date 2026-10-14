import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol window calculation.
    protocol CareProtocolWindowFactor {
        func describe() -> String
        func adjust(_ item: CareProtocolWindow, value: Double) -> Double
    }

    final class FlaggedCareProtocolWindowAdjuster: CareProtocolWindowFactor {
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

        func adjust(_ item: CareProtocolWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCareProtocolWindowAdjuster: CareProtocolWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCareProtocolWindowAdjuster: CareProtocolWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SegmentCareProtocolWindowAdjuster: CareProtocolWindowFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: CareProtocolWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CareProtocolWindowWeightOffsetAdjuster: CareProtocolWindowFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: CareProtocolWindow, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    /// Runs the care protocol window steps in order and keeps a trace of each.
    final class CareProtocolWindowEngine {
        var steps: [any CareProtocolWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareProtocolWindow) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolWindowFactor = steps[index]
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

        func evaluateAll(_ items: [CareProtocolWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareProtocolWindowEngine(_ flags: Kit.Flags.Registry) -> CareProtocolWindowEngine {
        return CareProtocolWindowEngine(
            steps: [
                FlaggedCareProtocolWindowAdjuster(flags: flags, flag: "care-protocol-window-capped", percent: 4.0),
                PercentCareProtocolWindowAdjuster(percent: -20.3),
                CapCareProtocolWindowAdjuster(cap: 42407.0),
                SegmentCareProtocolWindowAdjuster(factors: ["south": 0.78]),
                CareProtocolWindowWeightOffsetAdjuster(weight: 1.49),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 38002.2
        )
    }
}
