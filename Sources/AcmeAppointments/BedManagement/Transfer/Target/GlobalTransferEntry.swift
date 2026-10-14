import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global transfer entry is in its life cycle.
    enum GlobalTransferEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global transfer entry as the transfer team keeps it.
    final class GlobalTransferEntry {
        var code: String
        var title: String
        var locale: String
        var minimum: Double
        var graceDays: Int
        var pinned: Bool
        var patientRef: String
        var country: String
        var status: GlobalTransferEntryStatus

        init(code: String, title: String, locale: String, minimum: Double, graceDays: Int, pinned: Bool, patientRef: String, country: String, status: GlobalTransferEntryStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.minimum = minimum
            self.graceDays = graceDays
            self.pinned = pinned
            self.patientRef = patientRef
            self.country = country
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

        func canMoveTo(_ next: GlobalTransferEntryStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == GlobalTransferEntryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalTransferEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global transfer entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return ((minimum + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalTransferEntry {
            return GlobalTransferEntry(
                code: code,
                title: title,
                locale: locale,
                minimum: minimum,
                graceDays: graceDays,
                pinned: pinned,
                patientRef: patientRef,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global transfer entry in status requested.
    static func newGlobalTransferEntry(_ code: String, title: String) -> GlobalTransferEntry {
        return GlobalTransferEntry(
            code: code,
            title: title,
            locale: "",
            minimum: 0.0,
            graceDays: 0,
            pinned: false,
            patientRef: "",
            country: "",
            status: GlobalTransferEntryStatus.requested
        )
    }
}
