import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialBaselinesForProfile(_ items: [CredentialBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveFloatPoolProfilesFromBaseline(_ items: [CredentialBaseline]) -> [FloatPoolProfile] {
        var out: [FloatPoolProfile] = []
        for item in items {
            let derived = newFloatPoolProfile(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignFloatPoolProfile(_ item: FloatPoolProfile) -> String {
        return globalCredentialWindowBucket(item.projectedExposure())
    }
}
