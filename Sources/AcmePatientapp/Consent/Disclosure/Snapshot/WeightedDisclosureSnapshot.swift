import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted disclosure snapshot is in its life cycle.
    enum WeightedDisclosureSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted disclosure snapshot as the disclosure team keeps it.
    final class WeightedDisclosureSnapshot {
        var code: String
        var label: String
        var attempts: Int
        var reviewer: String
        var weight: Double
        var endsAt: Int
        var tags: [String]
        var locale: String
        var clinicianID: String
        var summary: String
        var cost: Double
        var status: WeightedDisclosureSnapshotStatus

        init(code: String, label: String, attempts: Int, reviewer: String, weight: Double, endsAt: Int, tags: [String], locale: String, clinicianID: String, summary: String, cost: Double, status: WeightedDisclosureSnapshotStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.reviewer = reviewer
            self.weight = weight
            self.endsAt = endsAt
            self.tags = tags
            self.locale = locale
            self.clinicianID = clinicianID
            self.summary = summary
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedDisclosureSnapshotStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedDisclosureSnapshotStatus.validated || next == WeightedDisclosureSnapshotStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == WeightedDisclosureSnapshotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedDisclosureSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted disclosure snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("weighted disclosure snapshot") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveVolume() -> Double {
            return (cost * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> WeightedDisclosureSnapshot {
            return WeightedDisclosureSnapshot(
                code: code,
                label: label,
                attempts: attempts,
                reviewer: reviewer,
                weight: weight,
                endsAt: endsAt,
                tags: tags,
                locale: locale,
                clinicianID: clinicianID,
                summary: summary,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a weighted disclosure snapshot in status created.
    static func newWeightedDisclosureSnapshot(_ code: String, label: String) -> WeightedDisclosureSnapshot {
        return WeightedDisclosureSnapshot(
            code: code,
            label: label,
            attempts: 0,
            reviewer: "",
            weight: 0.0,
            endsAt: 0,
            tags: [],
            locale: "",
            clinicianID: "",
            summary: "",
            cost: 0.0,
            status: WeightedDisclosureSnapshotStatus.created
        )
    }
}
