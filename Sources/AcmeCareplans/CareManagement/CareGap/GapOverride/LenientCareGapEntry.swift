import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient care gap entry is in its life cycle.
    enum LenientCareGapEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A lenient care gap entry. Its code is unique within a tenant.
    final class LenientCareGapEntry {
        var code: String
        var title: String
        var description: String
        var checksum: String
        var archived: Bool
        var contactEmail: String
        var label: String
        var quantity: Int
        var status: LenientCareGapEntryStatus

        init(code: String, title: String, description: String, checksum: String, archived: Bool, contactEmail: String, label: String, quantity: Int, status: LenientCareGapEntryStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.checksum = checksum
            self.archived = archived
            self.contactEmail = contactEmail
            self.label = label
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientCareGapEntryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LenientCareGapEntryStatus.ready || next == LenientCareGapEntryStatus.stopped
            case .ready:
                return next == LenientCareGapEntryStatus.draining || next == LenientCareGapEntryStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LenientCareGapEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient care gap entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient care gap entry") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> LenientCareGapEntry {
            return LenientCareGapEntry(
                code: code,
                title: title,
                description: description,
                checksum: checksum,
                archived: archived,
                contactEmail: contactEmail,
                label: label,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient care gap entry in status idle.
    static func newLenientCareGapEntry(_ code: String, title: String) -> LenientCareGapEntry {
        return LenientCareGapEntry(
            code: code,
            title: title,
            description: "",
            checksum: "",
            archived: false,
            contactEmail: "",
            label: "",
            quantity: 0,
            status: LenientCareGapEntryStatus.idle
        )
    }
}
