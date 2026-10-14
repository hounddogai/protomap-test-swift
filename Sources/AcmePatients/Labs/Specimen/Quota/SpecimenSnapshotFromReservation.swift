import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackAccessionReservationsForSnapshot(_ items: [FallbackAccessionReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveSpecimenSnapshotsFromReservation(_ items: [FallbackAccessionReservation]) -> [SpecimenSnapshot] {
        var out: [SpecimenSnapshot] = []
        for item in items {
            let derived = newSpecimenSnapshot(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchSpecimenSnapshot(_ item: SpecimenSnapshot) -> String {
        return accessionBaselineBucket(item.measuredValue())
    }
}
