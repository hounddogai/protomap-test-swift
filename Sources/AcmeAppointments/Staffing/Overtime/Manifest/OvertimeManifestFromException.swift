import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialExceptionsForManifest(_ items: [CredentialException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveOvertimeManifestsFromException(_ items: [CredentialException]) -> [OvertimeManifest] {
        var out: [OvertimeManifest] = []
        for item in items {
            let derived = newOvertimeManifest(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchOvertimeManifest(_ item: OvertimeManifest) -> String {
        return normalizeCredentialExceptionCode(item.code)
    }
}
