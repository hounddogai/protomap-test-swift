import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy transfer window is in its life cycle.
    enum LegacyTransferWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy transfer window. Its code is unique within a tenant.
    final class LegacyTransferWindow {
        var code: String
        var name: String
        var tags: [String]
        var expiresAt: Int
        var locale: String
        var rate: Double
        var notes: String
        var pinned: Bool
        var sequence: Int
        var updatedAt: Int
        var createdAt: Int
        var status: LegacyTransferWindowStatus

        init(code: String, name: String, tags: [String], expiresAt: Int, locale: String, rate: Double, notes: String, pinned: Bool, sequence: Int, updatedAt: Int, createdAt: Int, status: LegacyTransferWindowStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.expiresAt = expiresAt
            self.locale = locale
            self.rate = rate
            self.notes = notes
            self.pinned = pinned
            self.sequence = sequence
            self.updatedAt = updatedAt
            self.createdAt = createdAt
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

        func canMoveTo(_ next: LegacyTransferWindowStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LegacyTransferWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy transfer window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("legacy transfer window") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return ((Double(sequence) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyTransferWindow {
            return LegacyTransferWindow(
                code: code,
                name: name,
                tags: tags,
                expiresAt: expiresAt,
                locale: locale,
                rate: rate,
                notes: notes,
                pinned: pinned,
                sequence: sequence,
                updatedAt: updatedAt,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a legacy transfer window in status proposed.
    static func newLegacyTransferWindow(_ code: String, name: String) -> LegacyTransferWindow {
        return LegacyTransferWindow(
            code: code,
            name: name,
            tags: [],
            expiresAt: 0,
            locale: "",
            rate: 0.0,
            notes: "",
            pinned: false,
            sequence: 0,
            updatedAt: 0,
            createdAt: 0,
            status: LegacyTransferWindowStatus.proposed
        )
    }
}
