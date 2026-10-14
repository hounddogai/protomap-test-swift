import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the manual care protocol notice calculation.
    protocol ManualCareProtocolNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: ManualCareProtocolNotice, value: Double) -> Double
    }

    final class ManualCareProtocolNoticeFloorValueOffsetAdjuster: ManualCareProtocolNoticeAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: ManualCareProtocolNotice, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class CategoryManualCareProtocolNoticeAdjuster: ManualCareProtocolNoticeAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: ManualCareProtocolNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedManualCareProtocolNoticeAdjuster: ManualCareProtocolNoticeAdjuster {
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

        func adjust(_ item: ManualCareProtocolNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualCareProtocolNoticeAdjuster: ManualCareProtocolNoticeAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualCareProtocolNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual care protocol notice steps in order and keeps a trace of each.
    final class ManualCareProtocolNoticeEngine {
        var steps: [any ManualCareProtocolNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCareProtocolNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualCareProtocolNotice) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualCareProtocolNoticeAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualCareProtocolNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualCareProtocolNoticeEngine(_ flags: Kit.Flags.Registry) -> ManualCareProtocolNoticeEngine {
        return ManualCareProtocolNoticeEngine(
            steps: [
                ManualCareProtocolNoticeFloorValueOffsetAdjuster(weight: 0.09),
                CategoryManualCareProtocolNoticeAdjuster(factors: ["online": 0.8]),
                FlaggedManualCareProtocolNoticeAdjuster(
                    flags: flags,
                    flag: "manual-care-protocol-notice-global",
                    percent: -4.5
                ),
                CapManualCareProtocolNoticeAdjuster(cap: 5295.0),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 30248.3
        )
    }
}
