import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the manual credential mapping calculation.
    protocol ManualCredentialMappingModifier {
        func describe() -> String
        func adjust(_ item: ManualCredentialMapping, value: Double) -> Double
    }

    final class ManualCredentialMappingThresholdOffsetAdjuster: ManualCredentialMappingModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: ManualCredentialMapping, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class MinimumManualCredentialMappingAdjuster: ManualCredentialMappingModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualCredentialMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedManualCredentialMappingAdjuster: ManualCredentialMappingModifier {
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

        func adjust(_ item: ManualCredentialMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualCredentialMappingAdjuster: ManualCredentialMappingModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualCredentialMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingManualCredentialMappingAdjuster: ManualCredentialMappingModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualCredentialMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual credential mapping steps in order and keeps a trace of each.
    final class ManualCredentialMappingEngine {
        var steps: [any ManualCredentialMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCredentialMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualCredentialMapping) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ManualCredentialMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualCredentialMappingEngine(_ flags: Kit.Flags.Registry) -> ManualCredentialMappingEngine {
        return ManualCredentialMappingEngine(
            steps: [
                ManualCredentialMappingThresholdOffsetAdjuster(weight: 1.01),
                MinimumManualCredentialMappingAdjuster(minimum: 2.6),
                FlaggedManualCredentialMappingAdjuster(
                    flags: flags,
                    flag: "manual-credential-mapping-manual",
                    percent: -6.7
                ),
                CapManualCredentialMappingAdjuster(cap: 49761.0),
                RoundingManualCredentialMappingAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 77113.0
        )
    }
}
