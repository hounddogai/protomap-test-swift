import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary consent form proposal is in its life cycle.
    enum PrimaryConsentFormProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary consent form proposal as the consent form team keeps it.
    final class PrimaryConsentFormProposal {
        var code: String
        var name: String
        var floorValue: Double
        var minimum: Double
        var margin: Double
        var visitMinutes: Int
        var status: PrimaryConsentFormProposalStatus

        init(code: String, name: String, floorValue: Double, minimum: Double, margin: Double, visitMinutes: Int, status: PrimaryConsentFormProposalStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.minimum = minimum
            self.margin = margin
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: PrimaryConsentFormProposalStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PrimaryConsentFormProposalStatus.active || next == PrimaryConsentFormProposalStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == PrimaryConsentFormProposalStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryConsentFormProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary consent form proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary consent form proposal") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(visitMinutes) - margin) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryConsentFormProposal {
            return PrimaryConsentFormProposal(
                code: code,
                name: name,
                floorValue: floorValue,
                minimum: minimum,
                margin: margin,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary consent form proposal in status draft.
    static func newPrimaryConsentFormProposal(_ code: String, name: String) -> PrimaryConsentFormProposal {
        return PrimaryConsentFormProposal(
            code: code,
            name: name,
            floorValue: 0.0,
            minimum: 0.0,
            margin: 0.0,
            visitMinutes: 0,
            status: PrimaryConsentFormProposalStatus.draft
        )
    }
}
