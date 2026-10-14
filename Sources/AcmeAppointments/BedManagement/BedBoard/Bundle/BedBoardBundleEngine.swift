import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board bundle calculation.
    protocol BedBoardBundleStep {
        func describe() -> String
        func adjust(_ item: BedBoardBundle, value: Double) -> Double
    }

    final class BedBoardBundleMarginOffsetAdjuster: BedBoardBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: BedBoardBundle, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class CapBedBoardBundleAdjuster: BedBoardBundleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBedBoardBundleAdjuster: BedBoardBundleStep {
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

        func adjust(_ item: BedBoardBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityBedBoardBundleAdjuster: BedBoardBundleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: BedBoardBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the bed board bundle steps in order and keeps a trace of each.
    final class BedBoardBundleEngine {
        var steps: [any BedBoardBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BedBoardBundle) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardBundleStep = steps[index]
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

        func evaluateAll(_ items: [BedBoardBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBedBoardBundleEngine(_ flags: Kit.Flags.Registry) -> BedBoardBundleEngine {
        return BedBoardBundleEngine(
            steps: [
                BedBoardBundleMarginOffsetAdjuster(weight: 1.23),
                CapBedBoardBundleAdjuster(cap: 6034.0),
                FlaggedBedBoardBundleAdjuster(flags: flags, flag: "bed-board-bundle-manual", percent: -4.8),
                FacilityBedBoardBundleAdjuster(factors: ["east": 0.78]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 17756.4
        )
    }
}
