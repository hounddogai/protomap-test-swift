import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read quota is in its life cycle.
    enum ReadQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One read quota, with what the planners need to act on it.
    final class ReadQuota {
        var code: String
        var title: String
        var notes: String
        var expiresAt: Int
        var margin: Double
        var phone: String
        var status: ReadQuotaStatus

        init(code: String, title: String, notes: String, expiresAt: Int, margin: Double, phone: String, status: ReadQuotaStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.expiresAt = expiresAt
            self.margin = margin
            self.phone = phone
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

        func canMoveTo(_ next: ReadQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ReadQuotaStatus.approved || next == ReadQuotaStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ReadQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedTotal() -> Double {
            return ((Double(expiresAt) - margin) * 100).rounded() / 100
        }

        func copyValue() -> ReadQuota {
            return ReadQuota(
                code: code,
                title: title,
                notes: notes,
                expiresAt: expiresAt,
                margin: margin,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a read quota in status proposed.
    static func newReadQuota(_ code: String, title: String) -> ReadQuota {
        return ReadQuota(
            code: code,
            title: title,
            notes: "",
            expiresAt: 0,
            margin: 0.0,
            phone: "",
            status: ReadQuotaStatus.proposed
        )
    }
}
