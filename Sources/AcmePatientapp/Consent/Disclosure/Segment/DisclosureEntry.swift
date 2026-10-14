import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure entry is in its life cycle.
    enum DisclosureEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One disclosure entry, with what the planners need to act on it.
    final class DisclosureEntry {
        var code: String
        var label: String
        var ward: String
        var weight: Double
        var checksum: String
        var expiresAt: Int
        var limit: Int
        var facility: String
        var margin: Double
        var minimum: Double
        var status: DisclosureEntryStatus

        init(code: String, label: String, ward: String, weight: Double, checksum: String, expiresAt: Int, limit: Int, facility: String, margin: Double, minimum: Double, status: DisclosureEntryStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.weight = weight
            self.checksum = checksum
            self.expiresAt = expiresAt
            self.limit = limit
            self.facility = facility
            self.margin = margin
            self.minimum = minimum
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

        func canMoveTo(_ next: DisclosureEntryStatus) -> Bool {
            switch status {
            case .draft:
                return next == DisclosureEntryStatus.active || next == DisclosureEntryStatus.closed
            case .pending:
                return next == DisclosureEntryStatus.suspended
            case .active:
                return next == DisclosureEntryStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: DisclosureEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("disclosure entry") \(code)"
        }

        func adjustedTotal() -> Double {
            return (minimum * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureEntry {
            return DisclosureEntry(
                code: code,
                label: label,
                ward: ward,
                weight: weight,
                checksum: checksum,
                expiresAt: expiresAt,
                limit: limit,
                facility: facility,
                margin: margin,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a disclosure entry in status draft.
    static func newDisclosureEntry(_ code: String, label: String) -> DisclosureEntry {
        return DisclosureEntry(
            code: code,
            label: label,
            ward: "",
            weight: 0.0,
            checksum: "",
            expiresAt: 0,
            limit: 0,
            facility: "",
            margin: 0.0,
            minimum: 0.0,
            status: DisclosureEntryStatus.draft
        )
    }
}
