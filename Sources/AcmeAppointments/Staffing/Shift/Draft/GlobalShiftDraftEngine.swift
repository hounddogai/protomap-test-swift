import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global shift draft calculation.
    protocol GlobalShiftDraftModifier {
        func describe() -> String
        func adjust(_ item: GlobalShiftDraft, value: Double) -> Double
    }

    final class PercentGlobalShiftDraftAdjuster: GlobalShiftDraftModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalShiftDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalShiftDraftAdjuster: GlobalShiftDraftModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalShiftDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GlobalShiftDraftStartsAtOffsetAdjuster: GlobalShiftDraftModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: GlobalShiftDraft, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingGlobalShiftDraftAdjuster: GlobalShiftDraftModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalShiftDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global shift draft steps in order and keeps a trace of each.
    final class GlobalShiftDraftEngine {
        var steps: [any GlobalShiftDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalShiftDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalShiftDraft) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [GlobalShiftDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalShiftDraftEngine() -> GlobalShiftDraftEngine {
        return GlobalShiftDraftEngine(
            steps: [
                PercentGlobalShiftDraftAdjuster(percent: 1.3),
                CapGlobalShiftDraftAdjuster(cap: 22717.0),
                GlobalShiftDraftStartsAtOffsetAdjuster(weight: 0.73),
                RoundingGlobalShiftDraftAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 55092.8
        )
    }
}
