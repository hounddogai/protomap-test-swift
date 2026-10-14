import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending statement notice is in its life cycle.
    enum PendingStatementNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A pending statement notice. Its code is unique within a tenant.
    final class PendingStatementNotice {
        var code: String
        var title: String
        var endsAt: Int
        var budget: Double
        var durationMinutes: Int
        var quantity: Int
        var startsAt: Int
        var updatedAt: Int
        var ward: String
        var attributes: [String: String]
        var acuity: Int
        var status: PendingStatementNoticeStatus

        init(code: String, title: String, endsAt: Int, budget: Double, durationMinutes: Int, quantity: Int, startsAt: Int, updatedAt: Int, ward: String, attributes: [String: String], acuity: Int, status: PendingStatementNoticeStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.quantity = quantity
            self.startsAt = startsAt
            self.updatedAt = updatedAt
            self.ward = ward
            self.attributes = attributes
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingStatementNoticeStatus) -> Bool {
            switch status {
            case .requested:
                return next == PendingStatementNoticeStatus.granted
            case .granted:
                return next == PendingStatementNoticeStatus.revoked || next == PendingStatementNoticeStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PendingStatementNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending statement notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("pending statement notice") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netTotal() -> Double {
            return ((Double(updatedAt) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PendingStatementNotice {
            return PendingStatementNotice(
                code: code,
                title: title,
                endsAt: endsAt,
                budget: budget,
                durationMinutes: durationMinutes,
                quantity: quantity,
                startsAt: startsAt,
                updatedAt: updatedAt,
                ward: ward,
                attributes: attributes,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a pending statement notice in status requested.
    static func newPendingStatementNotice(_ code: String, title: String) -> PendingStatementNotice {
        return PendingStatementNotice(
            code: code,
            title: title,
            endsAt: 0,
            budget: 0.0,
            durationMinutes: 0,
            quantity: 0,
            startsAt: 0,
            updatedAt: 0,
            ward: "",
            attributes: [:],
            acuity: 0,
            status: PendingStatementNoticeStatus.requested
        )
    }
}
