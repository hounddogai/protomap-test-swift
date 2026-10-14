import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped reference range agreement is in its life cycle.
    enum CappedReferenceRangeAgreementStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A capped reference range agreement as the reference range team keeps it.
    final class CappedReferenceRangeAgreement {
        var code: String
        var name: String
        var startsAt: Int
        var capacity: Int
        var ownerID: String
        var encounterID: String
        var archived: Bool
        var summary: String
        var ward: String
        var status: CappedReferenceRangeAgreementStatus

        init(code: String, name: String, startsAt: Int, capacity: Int, ownerID: String, encounterID: String, archived: Bool, summary: String, ward: String, status: CappedReferenceRangeAgreementStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.capacity = capacity
            self.ownerID = ownerID
            self.encounterID = encounterID
            self.archived = archived
            self.summary = summary
            self.ward = ward
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedReferenceRangeAgreementStatus) -> Bool {
            switch status {
            case .planned:
                return next == CappedReferenceRangeAgreementStatus.completed || next == CappedReferenceRangeAgreementStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CappedReferenceRangeAgreementStatus.completed || next == CappedReferenceRangeAgreementStatus.cancelled
            case .completed:
                return next == CappedReferenceRangeAgreementStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedReferenceRangeAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped reference range agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedValue() -> Double {
            return ((Double(capacity) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedReferenceRangeAgreement {
            return CappedReferenceRangeAgreement(
                code: code,
                name: name,
                startsAt: startsAt,
                capacity: capacity,
                ownerID: ownerID,
                encounterID: encounterID,
                archived: archived,
                summary: summary,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a capped reference range agreement in status planned.
    static func newCappedReferenceRangeAgreement(_ code: String, name: String) -> CappedReferenceRangeAgreement {
        return CappedReferenceRangeAgreement(
            code: code,
            name: name,
            startsAt: 0,
            capacity: 0,
            ownerID: "",
            encounterID: "",
            archived: false,
            summary: "",
            ward: "",
            status: CappedReferenceRangeAgreementStatus.planned
        )
    }
}
