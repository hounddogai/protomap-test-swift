import AcmePlatform
import Foundation

extension Consent {
    /// One step of the global revocation record calculation.
    protocol GlobalRevocationRecordAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalRevocationRecord, value: Double) -> Double
    }

    final class MinimumGlobalRevocationRecordAdjuster: GlobalRevocationRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalRevocationRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedGlobalRevocationRecordAdjuster: GlobalRevocationRecordAdjuster {
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

        func adjust(_ item: GlobalRevocationRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleGlobalRevocationRecordAdjuster: GlobalRevocationRecordAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GlobalRevocationRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapGlobalRevocationRecordAdjuster: GlobalRevocationRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalRevocationRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global revocation record steps in order and keeps a trace of each.
    final class GlobalRevocationRecordEngine {
        var steps: [any GlobalRevocationRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalRevocationRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalRevocationRecord) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [GlobalRevocationRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalRevocationRecordEngine(_ flags: Kit.Flags.Registry) -> GlobalRevocationRecordEngine {
        return GlobalRevocationRecordEngine(
            steps: [
                MinimumGlobalRevocationRecordAdjuster(minimum: 10.2),
                FlaggedGlobalRevocationRecordAdjuster(
                    flags: flags,
                    flag: "global-revocation-record-capped",
                    percent: 3.2
                ),
                TitleGlobalRevocationRecordAdjuster(factors: ["north": 1.0, "retail": 1.29]),
                CapGlobalRevocationRecordAdjuster(cap: 35209.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 85663.5
        )
    }
}
