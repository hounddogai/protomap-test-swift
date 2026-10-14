import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study agreement is in its life cycle.
    enum StudyAgreementStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A study agreement as the study team keeps it.
    final class StudyAgreement {
        var code: String
        var title: String
        var description: String
        var createdAt: Int
        var revision: Int
        var procedureCode: String
        var payer: String
        var category: String
        var cost: Double
        var expiresAt: Int
        var status: StudyAgreementStatus

        init(code: String, title: String, description: String, createdAt: Int, revision: Int, procedureCode: String, payer: String, category: String, cost: Double, expiresAt: Int, status: StudyAgreementStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.createdAt = createdAt
            self.revision = revision
            self.procedureCode = procedureCode
            self.payer = payer
            self.category = category
            self.cost = cost
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: StudyAgreementStatus) -> Bool {
            switch status {
            case .planned:
                return next == StudyAgreementStatus.completed
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == StudyAgreementStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("study agreement") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(revision) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> StudyAgreement {
            return StudyAgreement(
                code: code,
                title: title,
                description: description,
                createdAt: createdAt,
                revision: revision,
                procedureCode: procedureCode,
                payer: payer,
                category: category,
                cost: cost,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a study agreement in status planned.
    static func newStudyAgreement(_ code: String, title: String) -> StudyAgreement {
        return StudyAgreement(
            code: code,
            title: title,
            description: "",
            createdAt: 0,
            revision: 0,
            procedureCode: "",
            payer: "",
            category: "",
            cost: 0.0,
            expiresAt: 0,
            status: StudyAgreementStatus.planned
        )
    }
}
