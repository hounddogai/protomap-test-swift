import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network agreement is in its life cycle.
    enum NetworkAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A network agreement. Its code is unique within a tenant.
    final class NetworkAgreement {
        var code: String
        var label: String
        var rate: Double
        var attempts: Int
        var clinicianID: String
        var externalRef: String
        var contactEmail: String
        var patientRef: String
        var cost: Double
        var expiresAt: Int
        var region: String
        var status: NetworkAgreementStatus

        init(code: String, label: String, rate: Double, attempts: Int, clinicianID: String, externalRef: String, contactEmail: String, patientRef: String, cost: Double, expiresAt: Int, region: String, status: NetworkAgreementStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.attempts = attempts
            self.clinicianID = clinicianID
            self.externalRef = externalRef
            self.contactEmail = contactEmail
            self.patientRef = patientRef
            self.cost = cost
            self.expiresAt = expiresAt
            self.region = region
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

        func canMoveTo(_ next: NetworkAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == NetworkAgreementStatus.rejected || next == NetworkAgreementStatus.withdrawn
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

        func moveTo(_ next: NetworkAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedValue() -> Double {
            return ((rate + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkAgreement {
            return NetworkAgreement(
                code: code,
                label: label,
                rate: rate,
                attempts: attempts,
                clinicianID: clinicianID,
                externalRef: externalRef,
                contactEmail: contactEmail,
                patientRef: patientRef,
                cost: cost,
                expiresAt: expiresAt,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a network agreement in status proposed.
    static func newNetworkAgreement(_ code: String, label: String) -> NetworkAgreement {
        return NetworkAgreement(
            code: code,
            label: label,
            rate: 0.0,
            attempts: 0,
            clinicianID: "",
            externalRef: "",
            contactEmail: "",
            patientRef: "",
            cost: 0.0,
            expiresAt: 0,
            region: "",
            status: NetworkAgreementStatus.proposed
        )
    }
}
