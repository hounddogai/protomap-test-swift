import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary rounding template is in its life cycle.
    enum PrimaryRoundingTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary rounding template. Its code is unique within a tenant.
    final class PrimaryRoundingTemplate {
        var code: String
        var title: String
        var payer: String
        var acuity: Int
        var archived: Bool
        var margin: Double
        var summary: String
        var clinicianID: String
        var contactEmail: String
        var status: PrimaryRoundingTemplateStatus

        init(code: String, title: String, payer: String, acuity: Int, archived: Bool, margin: Double, summary: String, clinicianID: String, contactEmail: String, status: PrimaryRoundingTemplateStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.acuity = acuity
            self.archived = archived
            self.margin = margin
            self.summary = summary
            self.clinicianID = clinicianID
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryRoundingTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PrimaryRoundingTemplateStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PrimaryRoundingTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary rounding template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedVolume() -> Double {
            return ((margin + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRoundingTemplate {
            return PrimaryRoundingTemplate(
                code: code,
                title: title,
                payer: payer,
                acuity: acuity,
                archived: archived,
                margin: margin,
                summary: summary,
                clinicianID: clinicianID,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary rounding template in status open.
    static func newPrimaryRoundingTemplate(_ code: String, title: String) -> PrimaryRoundingTemplate {
        return PrimaryRoundingTemplate(
            code: code,
            title: title,
            payer: "",
            acuity: 0,
            archived: false,
            margin: 0.0,
            summary: "",
            clinicianID: "",
            contactEmail: "",
            status: PrimaryRoundingTemplateStatus.`open`
        )
    }
}
