import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped cleaning agreement is in its life cycle.
    enum CappedCleaningAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One capped cleaning agreement, with what the planners need to act on it.
    final class CappedCleaningAgreement {
        var code: String
        var label: String
        var title: String
        var timezone: String
        var batchSize: Int
        var allergy: String
        var clinicianID: String
        var archived: Bool
        var startsAt: Int
        var category: String
        var status: CappedCleaningAgreementStatus

        init(code: String, label: String, title: String, timezone: String, batchSize: Int, allergy: String, clinicianID: String, archived: Bool, startsAt: Int, category: String, status: CappedCleaningAgreementStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.timezone = timezone
            self.batchSize = batchSize
            self.allergy = allergy
            self.clinicianID = clinicianID
            self.archived = archived
            self.startsAt = startsAt
            self.category = category
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

        func canMoveTo(_ next: CappedCleaningAgreementStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CappedCleaningAgreementStatus.active || next == CappedCleaningAgreementStatus.suspended
            case .active:
                return next == CappedCleaningAgreementStatus.suspended || next == CappedCleaningAgreementStatus.closed
            case .suspended:
                return next == CappedCleaningAgreementStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedCleaningAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped cleaning agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedValue() -> Double {
            return (Double(batchSize) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedCleaningAgreement {
            return CappedCleaningAgreement(
                code: code,
                label: label,
                title: title,
                timezone: timezone,
                batchSize: batchSize,
                allergy: allergy,
                clinicianID: clinicianID,
                archived: archived,
                startsAt: startsAt,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a capped cleaning agreement in status draft.
    static func newCappedCleaningAgreement(_ code: String, label: String) -> CappedCleaningAgreement {
        return CappedCleaningAgreement(
            code: code,
            label: label,
            title: "",
            timezone: "",
            batchSize: 0,
            allergy: "",
            clinicianID: "",
            archived: false,
            startsAt: 0,
            category: "",
            status: CappedCleaningAgreementStatus.draft
        )
    }
}
