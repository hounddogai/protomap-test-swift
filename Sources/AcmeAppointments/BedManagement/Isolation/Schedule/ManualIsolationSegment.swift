import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual isolation segment is in its life cycle.
    enum ManualIsolationSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One manual isolation segment, with what the planners need to act on it.
    final class ManualIsolationSegment {
        var code: String
        var name: String
        var contactEmail: String
        var timezone: String
        var clinicianID: String
        var category: String
        var score: Double
        var status: ManualIsolationSegmentStatus

        init(code: String, name: String, contactEmail: String, timezone: String, clinicianID: String, category: String, score: Double, status: ManualIsolationSegmentStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.timezone = timezone
            self.clinicianID = clinicianID
            self.category = category
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualIsolationSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ManualIsolationSegmentStatus.closed
            case .suspended:
                return next == ManualIsolationSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualIsolationSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual isolation segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ManualIsolationSegment {
            return ManualIsolationSegment(
                code: code,
                name: name,
                contactEmail: contactEmail,
                timezone: timezone,
                clinicianID: clinicianID,
                category: category,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual isolation segment in status draft.
    static func newManualIsolationSegment(_ code: String, name: String) -> ManualIsolationSegment {
        return ManualIsolationSegment(
            code: code,
            name: name,
            contactEmail: "",
            timezone: "",
            clinicianID: "",
            category: "",
            score: 0.0,
            status: ManualIsolationSegmentStatus.draft
        )
    }
}
