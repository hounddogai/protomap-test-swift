import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read rollup is in its life cycle.
    enum ReadRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One read rollup, with what the planners need to act on it.
    final class ReadRollup {
        var code: String
        var title: String
        var quantity: Int
        var sequence: Int
        var endsAt: Int
        var discount: Double
        var contactEmail: String
        var summary: String
        var expiresAt: Int
        var segment: String
        var description: String
        var status: ReadRollupStatus

        init(code: String, title: String, quantity: Int, sequence: Int, endsAt: Int, discount: Double, contactEmail: String, summary: String, expiresAt: Int, segment: String, description: String, status: ReadRollupStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.sequence = sequence
            self.endsAt = endsAt
            self.discount = discount
            self.contactEmail = contactEmail
            self.summary = summary
            self.expiresAt = expiresAt
            self.segment = segment
            self.description = description
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

        func canMoveTo(_ next: ReadRollupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ReadRollupStatus.revoked || next == ReadRollupStatus.expired
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

        func moveTo(_ next: ReadRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedValue() -> Double {
            return ((discount - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ReadRollup {
            return ReadRollup(
                code: code,
                title: title,
                quantity: quantity,
                sequence: sequence,
                endsAt: endsAt,
                discount: discount,
                contactEmail: contactEmail,
                summary: summary,
                expiresAt: expiresAt,
                segment: segment,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a read rollup in status requested.
    static func newReadRollup(_ code: String, title: String) -> ReadRollup {
        return ReadRollup(
            code: code,
            title: title,
            quantity: 0,
            sequence: 0,
            endsAt: 0,
            discount: 0.0,
            contactEmail: "",
            summary: "",
            expiresAt: 0,
            segment: "",
            description: "",
            status: ReadRollupStatus.requested
        )
    }
}
