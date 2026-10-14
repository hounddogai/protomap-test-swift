import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenMetricsForProposal(_ items: [SpecimenMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveCourierProposalsFromMetric(_ items: [SpecimenMetric]) -> [CourierProposal] {
        var out: [CourierProposal] = []
        for item in items {
            let derived = newCourierProposal(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreCourierProposal(_ item: CourierProposal) -> String {
        return classifySpecimenTemplate(item.netValue())
    }

    static func summarizeAccessionMetricsForProposal(_ items: [AccessionMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveCourierProposalsFromMetricExtra(_ items: [AccessionMetric]) -> [CourierProposal] {
        var out: [CourierProposal] = []
        for item in items {
            let derived = newCourierProposal(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreCourierProposalExtra(_ item: CourierProposal) -> String {
        return accessionPreferenceBucket(item.netValue())
    }
}
