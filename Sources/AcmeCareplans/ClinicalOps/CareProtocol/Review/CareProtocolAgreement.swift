import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol agreement is in its life cycle.
    enum CareProtocolAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A care protocol agreement as the care protocol team keeps it.
    final class CareProtocolAgreement {
        var code: String
        var title: String
        var rate: Double
        var name: String
        var externalRef: String
        var minimum: Double
        var budget: Double
        var payer: String
        var limit: Int
        var archived: Bool
        var refills: Int
        var status: CareProtocolAgreementStatus

        init(code: String, title: String, rate: Double, name: String, externalRef: String, minimum: Double, budget: Double, payer: String, limit: Int, archived: Bool, refills: Int, status: CareProtocolAgreementStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.name = name
            self.externalRef = externalRef
            self.minimum = minimum
            self.budget = budget
            self.payer = payer
            self.limit = limit
            self.archived = archived
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CareProtocolAgreementStatus.approved
            case .approved:
                return next == CareProtocolAgreementStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: CareProtocolAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedVolume() -> Double {
            return ((minimum - budget) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolAgreement {
            return CareProtocolAgreement(
                code: code,
                title: title,
                rate: rate,
                name: name,
                externalRef: externalRef,
                minimum: minimum,
                budget: budget,
                payer: payer,
                limit: limit,
                archived: archived,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care protocol agreement in status proposed.
    static func newCareProtocolAgreement(_ code: String, title: String) -> CareProtocolAgreement {
        return CareProtocolAgreement(
            code: code,
            title: title,
            rate: 0.0,
            name: "",
            externalRef: "",
            minimum: 0.0,
            budget: 0.0,
            payer: "",
            limit: 0,
            archived: false,
            refills: 0,
            status: CareProtocolAgreementStatus.proposed
        )
    }
}
