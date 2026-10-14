import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality segment calculation.
    protocol ModalitySegmentStep {
        func describe() -> String
        func adjust(_ item: ModalitySegment, value: Double) -> Double
    }

    final class PercentModalitySegmentAdjuster: ModalitySegmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalitySegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ModalitySegmentRefillsOffsetAdjuster: ModalitySegmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: ModalitySegment, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class RoundingModalitySegmentAdjuster: ModalitySegmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalitySegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapModalitySegmentAdjuster: ModalitySegmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalitySegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedModalitySegmentAdjuster: ModalitySegmentStep {
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

        func adjust(_ item: ModalitySegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the modality segment steps in order and keeps a trace of each.
    final class ModalitySegmentEngine {
        var steps: [any ModalitySegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalitySegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ModalitySegment) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [ModalitySegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultModalitySegmentEngine(_ flags: Kit.Flags.Registry) -> ModalitySegmentEngine {
        return ModalitySegmentEngine(
            steps: [
                PercentModalitySegmentAdjuster(percent: -5.9),
                ModalitySegmentRefillsOffsetAdjuster(weight: 1.54),
                RoundingModalitySegmentAdjuster(step: 0.1),
                CapModalitySegmentAdjuster(cap: 8793.0),
                FlaggedModalitySegmentAdjuster(flags: flags, flag: "modality-segment-scheduled", percent: -3.8),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 29110.9
        )
    }
}
