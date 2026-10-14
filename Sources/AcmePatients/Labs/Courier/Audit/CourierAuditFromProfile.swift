import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierProfilesForAudit(_ items: [CourierProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveCourierAuditsFromProfile(_ items: [CourierProfile]) -> [CourierAudit] {
        var out: [CourierAudit] = []
        for item in items {
            let derived = newCourierAudit(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planCourierAudit(_ item: CourierAudit) -> String {
        return normalizeDefaultCourierProposalCode(item.code)
    }
}
