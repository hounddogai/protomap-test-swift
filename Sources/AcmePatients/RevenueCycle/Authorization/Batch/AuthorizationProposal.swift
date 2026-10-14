import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization proposal is in its life cycle.
    enum AuthorizationProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A authorization proposal. Its code is unique within a tenant.
    final class AuthorizationProposal {
        var code: String
        var label: String
        var threshold: Double
        var rate: Double
        var floorValue: Double
        var endsAt: Int
        var patientRef: String
        var windowDays: Int
        var ratio: Double
        var sequence: Int
        var status: AuthorizationProposalStatus

        init(code: String, label: String, threshold: Double, rate: Double, floorValue: Double, endsAt: Int, patientRef: String, windowDays: Int, ratio: Double, sequence: Int, status: AuthorizationProposalStatus) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.rate = rate
            self.floorValue = floorValue
            self.endsAt = endsAt
            self.patientRef = patientRef
            self.windowDays = windowDays
            self.ratio = ratio
            self.sequence = sequence
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

        func canMoveTo(_ next: AuthorizationProposalStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AuthorizationProposalStatus.rejected || next == AuthorizationProposalStatus.withdrawn
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

        func moveTo(_ next: AuthorizationProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("authorization proposal") \(code)"
        }

        func weightedTotal() -> Double {
            return ((threshold + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationProposal {
            return AuthorizationProposal(
                code: code,
                label: label,
                threshold: threshold,
                rate: rate,
                floorValue: floorValue,
                endsAt: endsAt,
                patientRef: patientRef,
                windowDays: windowDays,
                ratio: ratio,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a authorization proposal in status proposed.
    static func newAuthorizationProposal(_ code: String, label: String) -> AuthorizationProposal {
        return AuthorizationProposal(
            code: code,
            label: label,
            threshold: 0.0,
            rate: 0.0,
            floorValue: 0.0,
            endsAt: 0,
            patientRef: "",
            windowDays: 0,
            ratio: 0.0,
            sequence: 0,
            status: AuthorizationProposalStatus.proposed
        )
    }
}
