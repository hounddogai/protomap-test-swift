import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual network agreement is in its life cycle.
    enum ManualNetworkAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual network agreement. Its code is unique within a tenant.
    final class ManualNetworkAgreement {
        var code: String
        var name: String
        var checksum: String
        var diagnosisCode: String
        var ceiling: Double
        var dosageMg: Double
        var status: ManualNetworkAgreementStatus

        init(code: String, name: String, checksum: String, diagnosisCode: String, ceiling: Double, dosageMg: Double, status: ManualNetworkAgreementStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.diagnosisCode = diagnosisCode
            self.ceiling = ceiling
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: ManualNetworkAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ManualNetworkAgreementStatus.rejected || next == ManualNetworkAgreementStatus.withdrawn
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

        func moveTo(_ next: ManualNetworkAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual network agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netLoad() -> Double {
            return (dosageMg * ceiling * 100).rounded() / 100
        }

        func copyValue() -> ManualNetworkAgreement {
            return ManualNetworkAgreement(
                code: code,
                name: name,
                checksum: checksum,
                diagnosisCode: diagnosisCode,
                ceiling: ceiling,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual network agreement in status proposed.
    static func newManualNetworkAgreement(_ code: String, name: String) -> ManualNetworkAgreement {
        return ManualNetworkAgreement(
            code: code,
            name: name,
            checksum: "",
            diagnosisCode: "",
            ceiling: 0.0,
            dosageMg: 0.0,
            status: ManualNetworkAgreementStatus.proposed
        )
    }
}
