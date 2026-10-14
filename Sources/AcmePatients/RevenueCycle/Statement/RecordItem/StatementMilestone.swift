import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement milestone is in its life cycle.
    enum StatementMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A statement milestone. Its code is unique within a tenant.
    final class StatementMilestone {
        var code: String
        var name: String
        var archived: Bool
        var threshold: Double
        var country: String
        var procedureCode: String
        var clinicianID: String
        var payer: String
        var externalRef: String
        var patientRef: String
        var status: StatementMilestoneStatus

        init(code: String, name: String, archived: Bool, threshold: Double, country: String, procedureCode: String, clinicianID: String, payer: String, externalRef: String, patientRef: String, status: StatementMilestoneStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.threshold = threshold
            self.country = country
            self.procedureCode = procedureCode
            self.clinicianID = clinicianID
            self.payer = payer
            self.externalRef = externalRef
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StatementMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                return next == StatementMilestoneStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == StatementMilestoneStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("statement milestone") \(code)"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> StatementMilestone {
            return StatementMilestone(
                code: code,
                name: name,
                archived: archived,
                threshold: threshold,
                country: country,
                procedureCode: procedureCode,
                clinicianID: clinicianID,
                payer: payer,
                externalRef: externalRef,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a statement milestone in status requested.
    static func newStatementMilestone(_ code: String, name: String) -> StatementMilestone {
        return StatementMilestone(
            code: code,
            name: name,
            archived: false,
            threshold: 0.0,
            country: "",
            procedureCode: "",
            clinicianID: "",
            payer: "",
            externalRef: "",
            patientRef: "",
            status: StatementMilestoneStatus.requested
        )
    }
}
