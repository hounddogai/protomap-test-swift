import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling closure notice is in its life cycle.
    enum RollingClosureNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling closure notice. Its code is unique within a tenant.
    final class RollingClosureNotice {
        var code: String
        var title: String
        var checksum: String
        var payer: String
        var archived: Bool
        var currency: String
        var createdAt: Int
        var capacity: Int
        var minimum: Double
        var attributes: [String: String]
        var allergy: String
        var status: RollingClosureNoticeStatus

        init(code: String, title: String, checksum: String, payer: String, archived: Bool, currency: String, createdAt: Int, capacity: Int, minimum: Double, attributes: [String: String], allergy: String, status: RollingClosureNoticeStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.payer = payer
            self.archived = archived
            self.currency = currency
            self.createdAt = createdAt
            self.capacity = capacity
            self.minimum = minimum
            self.attributes = attributes
            self.allergy = allergy
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

        func canMoveTo(_ next: RollingClosureNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RollingClosureNoticeStatus.rejected || next == RollingClosureNoticeStatus.withdrawn
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

        func moveTo(_ next: RollingClosureNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling closure notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rolling closure notice") \(code)"
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

        func netLoad() -> Double {
            return (Double(capacity) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> RollingClosureNotice {
            return RollingClosureNotice(
                code: code,
                title: title,
                checksum: checksum,
                payer: payer,
                archived: archived,
                currency: currency,
                createdAt: createdAt,
                capacity: capacity,
                minimum: minimum,
                attributes: attributes,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling closure notice in status proposed.
    static func newRollingClosureNotice(_ code: String, title: String) -> RollingClosureNotice {
        return RollingClosureNotice(
            code: code,
            title: title,
            checksum: "",
            payer: "",
            archived: false,
            currency: "",
            createdAt: 0,
            capacity: 0,
            minimum: 0.0,
            attributes: [:],
            allergy: "",
            status: RollingClosureNoticeStatus.proposed
        )
    }
}
