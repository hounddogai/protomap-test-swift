import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default cleaning manifest is in its life cycle.
    enum DefaultCleaningManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One default cleaning manifest, with what the planners need to act on it.
    final class DefaultCleaningManifest {
        var code: String
        var label: String
        var batchSize: Int
        var graceDays: Int
        var notes: String
        var windowDays: Int
        var updatedAt: Int
        var expiresAt: Int
        var quantity: Int
        var status: DefaultCleaningManifestStatus

        init(code: String, label: String, batchSize: Int, graceDays: Int, notes: String, windowDays: Int, updatedAt: Int, expiresAt: Int, quantity: Int, status: DefaultCleaningManifestStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.graceDays = graceDays
            self.notes = notes
            self.windowDays = windowDays
            self.updatedAt = updatedAt
            self.expiresAt = expiresAt
            self.quantity = quantity
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

        func canMoveTo(_ next: DefaultCleaningManifestStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultCleaningManifestStatus.granted || next == DefaultCleaningManifestStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultCleaningManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default cleaning manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netLoad() -> Double {
            return ((Double(updatedAt) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCleaningManifest {
            return DefaultCleaningManifest(
                code: code,
                label: label,
                batchSize: batchSize,
                graceDays: graceDays,
                notes: notes,
                windowDays: windowDays,
                updatedAt: updatedAt,
                expiresAt: expiresAt,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default cleaning manifest in status requested.
    static func newDefaultCleaningManifest(_ code: String, label: String) -> DefaultCleaningManifest {
        return DefaultCleaningManifest(
            code: code,
            label: label,
            batchSize: 0,
            graceDays: 0,
            notes: "",
            windowDays: 0,
            updatedAt: 0,
            expiresAt: 0,
            quantity: 0,
            status: DefaultCleaningManifestStatus.requested
        )
    }
}
