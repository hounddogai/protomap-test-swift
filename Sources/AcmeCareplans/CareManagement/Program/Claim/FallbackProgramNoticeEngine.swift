import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback program notice calculation.
    protocol FallbackProgramNoticeFactor {
        func describe() -> String
        func adjust(_ item: FallbackProgramNotice, value: Double) -> Double
    }

    final class FallbackProgramNoticeAcuityOffsetAdjuster: FallbackProgramNoticeFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: FallbackProgramNotice, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class FlaggedFallbackProgramNoticeAdjuster: FallbackProgramNoticeFactor {
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

        func adjust(_ item: FallbackProgramNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackProgramNoticeAdjuster: FallbackProgramNoticeFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackProgramNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFallbackProgramNoticeAdjuster: FallbackProgramNoticeFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackProgramNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback program notice steps in order and keeps a trace of each.
    final class FallbackProgramNoticeEngine {
        var steps: [any FallbackProgramNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackProgramNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackProgramNotice) -> Double {
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

        func evaluateAll(_ items: [FallbackProgramNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackProgramNoticeEngine(_ flags: Kit.Flags.Registry) -> FallbackProgramNoticeEngine {
        return FallbackProgramNoticeEngine(
            steps: [
                FallbackProgramNoticeAcuityOffsetAdjuster(weight: 0.26),
                FlaggedFallbackProgramNoticeAdjuster(
                    flags: flags,
                    flag: "fallback-program-notice-manual",
                    percent: 1.0
                ),
                MinimumFallbackProgramNoticeAdjuster(minimum: 23.5),
                RoundingFallbackProgramNoticeAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 13587.1
        )
    }
}
