import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary transfer notice is in its life cycle.
    enum PrimaryTransferNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A primary transfer notice as the transfer team keeps it.
    final class PrimaryTransferNotice {
        var code: String
        var title: String
        var attributes: [String: String]
        var description: String
        var allergy: String
        var amount: Double
        var status: PrimaryTransferNoticeStatus

        init(code: String, title: String, attributes: [String: String], description: String, allergy: String, amount: Double, status: PrimaryTransferNoticeStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.description = description
            self.allergy = allergy
            self.amount = amount
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

        func canMoveTo(_ next: PrimaryTransferNoticeStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimaryTransferNoticeStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == PrimaryTransferNoticeStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryTransferNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary transfer notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
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

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> PrimaryTransferNotice {
            return PrimaryTransferNotice(
                code: code,
                title: title,
                attributes: attributes,
                description: description,
                allergy: allergy,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary transfer notice in status requested.
    static func newPrimaryTransferNotice(_ code: String, title: String) -> PrimaryTransferNotice {
        return PrimaryTransferNotice(
            code: code,
            title: title,
            attributes: [:],
            description: "",
            allergy: "",
            amount: 0.0,
            status: PrimaryTransferNoticeStatus.requested
        )
    }
}
