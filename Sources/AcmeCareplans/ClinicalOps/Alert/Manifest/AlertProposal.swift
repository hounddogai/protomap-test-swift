import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert proposal is in its life cycle.
    enum AlertProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A alert proposal as the alert team keeps it.
    final class AlertProposal {
        var code: String
        var name: String
        var floorValue: Double
        var checksum: String
        var discount: Double
        var status: AlertProposalStatus

        init(code: String, name: String, floorValue: Double, checksum: String, discount: Double, status: AlertProposalStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.checksum = checksum
            self.discount = discount
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

        func canMoveTo(_ next: AlertProposalStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == AlertProposalStatus.reopened || next == AlertProposalStatus.archived
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

        func moveTo(_ next: AlertProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return ((floorValue + discount) * 100).rounded() / 100
        }

        func copyValue() -> AlertProposal {
            return AlertProposal(
                code: code,
                name: name,
                floorValue: floorValue,
                checksum: checksum,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a alert proposal in status open.
    static func newAlertProposal(_ code: String, name: String) -> AlertProposal {
        return AlertProposal(
            code: code,
            name: name,
            floorValue: 0.0,
            checksum: "",
            discount: 0.0,
            status: AlertProposalStatus.`open`
        )
    }
}
