import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel agreement is in its life cycle.
    enum PanelAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A panel agreement as the panel team keeps it.
    final class PanelAgreement {
        var code: String
        var title: String
        var phone: String
        var summary: String
        var capacity: Int
        var ownerID: String
        var acuity: Int
        var status: PanelAgreementStatus

        init(code: String, title: String, phone: String, summary: String, capacity: Int, ownerID: String, acuity: Int, status: PanelAgreementStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.summary = summary
            self.capacity = capacity
            self.ownerID = ownerID
            self.acuity = acuity
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

        func canMoveTo(_ next: PanelAgreementStatus) -> Bool {
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
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PanelAgreementStatus.suspended || next == PanelAgreementStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PanelAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netTotal() -> Double {
            return (Double(acuity) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> PanelAgreement {
            return PanelAgreement(
                code: code,
                title: title,
                phone: phone,
                summary: summary,
                capacity: capacity,
                ownerID: ownerID,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a panel agreement in status draft.
    static func newPanelAgreement(_ code: String, title: String) -> PanelAgreement {
        return PanelAgreement(
            code: code,
            title: title,
            phone: "",
            summary: "",
            capacity: 0,
            ownerID: "",
            acuity: 0,
            status: PanelAgreementStatus.draft
        )
    }
}
