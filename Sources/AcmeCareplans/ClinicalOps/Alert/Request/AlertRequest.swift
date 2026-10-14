import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert request is in its life cycle.
    enum AlertRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A alert request as the alert team keeps it.
    final class AlertRequest {
        var code: String
        var title: String
        var margin: Double
        var archived: Bool
        var visible: Bool
        var country: String
        var phone: String
        var status: AlertRequestStatus

        init(code: String, title: String, margin: Double, archived: Bool, visible: Bool, country: String, phone: String, status: AlertRequestStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.archived = archived
            self.visible = visible
            self.country = country
            self.phone = phone
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

        func canMoveTo(_ next: AlertRequestStatus) -> Bool {
            switch status {
            case .draft:
                return next == AlertRequestStatus.suspended || next == AlertRequestStatus.closed
            case .pending:
                return next == AlertRequestStatus.active || next == AlertRequestStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AlertRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> AlertRequest {
            return AlertRequest(
                code: code,
                title: title,
                margin: margin,
                archived: archived,
                visible: visible,
                country: country,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a alert request in status draft.
    static func newAlertRequest(_ code: String, title: String) -> AlertRequest {
        return AlertRequest(
            code: code,
            title: title,
            margin: 0.0,
            archived: false,
            visible: false,
            country: "",
            phone: "",
            status: AlertRequestStatus.draft
        )
    }
}
