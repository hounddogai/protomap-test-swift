import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary recall request is in its life cycle.
    enum PrimaryRecallRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary recall request. Its code is unique within a tenant.
    final class PrimaryRecallRequest {
        var code: String
        var label: String
        var endsAt: Int
        var contactEmail: String
        var windowDays: Int
        var title: String
        var status: PrimaryRecallRequestStatus

        init(code: String, label: String, endsAt: Int, contactEmail: String, windowDays: Int, title: String, status: PrimaryRecallRequestStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.contactEmail = contactEmail
            self.windowDays = windowDays
            self.title = title
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

        func canMoveTo(_ next: PrimaryRecallRequestStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryRecallRequestStatus.active || next == PrimaryRecallRequestStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == PrimaryRecallRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryRecallRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary recall request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return ((Double(windowDays) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRecallRequest {
            return PrimaryRecallRequest(
                code: code,
                label: label,
                endsAt: endsAt,
                contactEmail: contactEmail,
                windowDays: windowDays,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary recall request in status draft.
    static func newPrimaryRecallRequest(_ code: String, label: String) -> PrimaryRecallRequest {
        return PrimaryRecallRequest(
            code: code,
            label: label,
            endsAt: 0,
            contactEmail: "",
            windowDays: 0,
            title: "",
            status: PrimaryRecallRequestStatus.draft
        )
    }
}
