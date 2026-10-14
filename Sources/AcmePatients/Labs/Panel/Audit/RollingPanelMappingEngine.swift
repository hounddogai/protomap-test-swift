import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling panel mapping calculation.
    protocol RollingPanelMappingAdjuster {
        func describe() -> String
        func adjust(_ item: RollingPanelMapping, value: Double) -> Double
    }

    final class PercentRollingPanelMappingAdjuster: RollingPanelMappingAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingPanelMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRollingPanelMappingAdjuster: RollingPanelMappingAdjuster {
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

        func adjust(_ item: RollingPanelMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingPanelMappingAdjuster: RollingPanelMappingAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingPanelMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RollingPanelMappingFloorValueOffsetAdjuster: RollingPanelMappingAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: RollingPanelMapping, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    /// Runs the rolling panel mapping steps in order and keeps a trace of each.
    final class RollingPanelMappingEngine {
        var steps: [any RollingPanelMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingPanelMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingPanelMapping) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingPanelMappingAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingPanelMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingPanelMappingEngine(_ flags: Kit.Flags.Registry) -> RollingPanelMappingEngine {
        return RollingPanelMappingEngine(
            steps: [
                PercentRollingPanelMappingAdjuster(percent: 13.9),
                FlaggedRollingPanelMappingAdjuster(flags: flags, flag: "rolling-panel-mapping-manual", percent: 8.2),
                RoundingRollingPanelMappingAdjuster(step: 0.1),
                RollingPanelMappingFloorValueOffsetAdjuster(weight: 0.11),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 62317.5
        )
    }
}
