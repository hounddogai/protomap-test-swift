import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense segment calculation.
    protocol DispenseSegmentStep {
        func describe() -> String
        func adjust(_ item: DispenseSegment, value: Double) -> Double
    }

    final class PercentDispenseSegmentAdjuster: DispenseSegmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDispenseSegmentAdjuster: DispenseSegmentStep {
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

        func adjust(_ item: DispenseSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleDispenseSegmentAdjuster: DispenseSegmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: DispenseSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DispenseSegmentVersionOffsetAdjuster: DispenseSegmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: DispenseSegment, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class RoundingDispenseSegmentAdjuster: DispenseSegmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the dispense segment steps in order and keeps a trace of each.
    final class DispenseSegmentEngine {
        var steps: [any DispenseSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DispenseSegment) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseSegmentStep = steps[index]
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

        func evaluateAll(_ items: [DispenseSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDispenseSegmentEngine(_ flags: Kit.Flags.Registry) -> DispenseSegmentEngine {
        return DispenseSegmentEngine(
            steps: [
                PercentDispenseSegmentAdjuster(percent: 18.0),
                FlaggedDispenseSegmentAdjuster(flags: flags, flag: "dispense-segment-capped", percent: -4.7),
                LocaleDispenseSegmentAdjuster(factors: ["south": 1.34, "east": 1.1, "north": 1.13]),
                DispenseSegmentVersionOffsetAdjuster(weight: 0.49),
                RoundingDispenseSegmentAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 28748.6
        )
    }
}
