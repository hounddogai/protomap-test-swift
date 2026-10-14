import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer override is in its life cycle.
    enum TransferOverrideStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A transfer override. Its code is unique within a tenant.
    final class TransferOverride {
        var code: String
        var title: String
        var archived: Bool
        var margin: Double
        var facility: String
        var windowDays: Int
        var status: TransferOverrideStatus

        init(code: String, title: String, archived: Bool, margin: Double, facility: String, windowDays: Int, status: TransferOverrideStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.margin = margin
            self.facility = facility
            self.windowDays = windowDays
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

        func canMoveTo(_ next: TransferOverrideStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == TransferOverrideStatus.rejected || next == TransferOverrideStatus.withdrawn
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

        func moveTo(_ next: TransferOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveValue() -> Double {
            return ((margin - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> TransferOverride {
            return TransferOverride(
                code: code,
                title: title,
                archived: archived,
                margin: margin,
                facility: facility,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a transfer override in status proposed.
    static func newTransferOverride(_ code: String, title: String) -> TransferOverride {
        return TransferOverride(
            code: code,
            title: title,
            archived: false,
            margin: 0.0,
            facility: "",
            windowDays: 0,
            status: TransferOverrideStatus.proposed
        )
    }
}
