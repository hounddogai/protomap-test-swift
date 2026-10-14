import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual specimen agreement is in its life cycle.
    enum ManualSpecimenAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One manual specimen agreement, with what the planners need to act on it.
    final class ManualSpecimenAgreement {
        var code: String
        var title: String
        var ownerID: String
        var cost: Double
        var retries: Int
        var createdAt: Int
        var dosageMg: Double
        var graceDays: Int
        var contactEmail: String
        var status: ManualSpecimenAgreementStatus

        init(code: String, title: String, ownerID: String, cost: Double, retries: Int, createdAt: Int, dosageMg: Double, graceDays: Int, contactEmail: String, status: ManualSpecimenAgreementStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.cost = cost
            self.retries = retries
            self.createdAt = createdAt
            self.dosageMg = dosageMg
            self.graceDays = graceDays
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ManualSpecimenAgreementStatus) -> Bool {
            switch status {
            case .draft:
                return next == ManualSpecimenAgreementStatus.pending || next == ManualSpecimenAgreementStatus.suspended
            case .pending:
                return next == ManualSpecimenAgreementStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ManualSpecimenAgreementStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualSpecimenAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual specimen agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return ((Double(graceDays) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualSpecimenAgreement {
            return ManualSpecimenAgreement(
                code: code,
                title: title,
                ownerID: ownerID,
                cost: cost,
                retries: retries,
                createdAt: createdAt,
                dosageMg: dosageMg,
                graceDays: graceDays,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual specimen agreement in status draft.
    static func newManualSpecimenAgreement(_ code: String, title: String) -> ManualSpecimenAgreement {
        return ManualSpecimenAgreement(
            code: code,
            title: title,
            ownerID: "",
            cost: 0.0,
            retries: 0,
            createdAt: 0,
            dosageMg: 0.0,
            graceDays: 0,
            contactEmail: "",
            status: ManualSpecimenAgreementStatus.draft
        )
    }
}
