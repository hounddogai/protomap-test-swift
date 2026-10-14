import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal care protocol proposal calculation.
    protocol SeasonalCareProtocolProposalModifier {
        func describe() -> String
        func adjust(_ item: SeasonalCareProtocolProposal, value: Double) -> Double
    }

    final class CapSeasonalCareProtocolProposalAdjuster: SeasonalCareProtocolProposalModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalCareProtocolProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SeasonalCareProtocolProposalVersionOffsetAdjuster: SeasonalCareProtocolProposalModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: SeasonalCareProtocolProposal, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class FlaggedSeasonalCareProtocolProposalAdjuster: SeasonalCareProtocolProposalModifier {
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

        func adjust(_ item: SeasonalCareProtocolProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal care protocol proposal steps in order and keeps a trace of each.
    final class SeasonalCareProtocolProposalEngine {
        var steps: [any SeasonalCareProtocolProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCareProtocolProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalCareProtocolProposal) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [SeasonalCareProtocolProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalCareProtocolProposalEngine(_ flags: Kit.Flags.Registry) -> SeasonalCareProtocolProposalEngine {
        return SeasonalCareProtocolProposalEngine(
            steps: [
                CapSeasonalCareProtocolProposalAdjuster(cap: 43467.0),
                SeasonalCareProtocolProposalVersionOffsetAdjuster(weight: 0.82),
                FlaggedSeasonalCareProtocolProposalAdjuster(
                    flags: flags,
                    flag: "seasonal-care-protocol-proposal-manual",
                    percent: 9.8
                ),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 91332.9
        )
    }
}
