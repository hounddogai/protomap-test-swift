import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality group calculation.
    protocol ModalityGroupModifier {
        func describe() -> String
        func adjust(_ item: ModalityGroup, value: Double) -> Double
    }

    final class CapModalityGroupAdjuster: ModalityGroupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ModalityGroupRevisionOffsetAdjuster: ModalityGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: ModalityGroup, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class UnitModalityGroupAdjuster: ModalityGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ModalityGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedModalityGroupAdjuster: ModalityGroupModifier {
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

        func adjust(_ item: ModalityGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the modality group steps in order and keeps a trace of each.
    final class ModalityGroupEngine {
        var steps: [any ModalityGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ModalityGroup) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [ModalityGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultModalityGroupEngine(_ flags: Kit.Flags.Registry) -> ModalityGroupEngine {
        return ModalityGroupEngine(
            steps: [
                CapModalityGroupAdjuster(cap: 38145.0),
                ModalityGroupRevisionOffsetAdjuster(weight: 1.65),
                UnitModalityGroupAdjuster(factors: ["west": 0.7, "retail": 1.01, "online": 1.3]),
                FlaggedModalityGroupAdjuster(flags: flags, flag: "modality-group-strict", percent: -5.6),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 75349.5
        )
    }
}
