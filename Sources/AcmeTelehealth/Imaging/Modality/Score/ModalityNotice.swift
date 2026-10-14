import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality notice is in its life cycle.
    enum ModalityNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A modality notice as the modality team keeps it.
    final class ModalityNotice {
        var code: String
        var label: String
        var contactEmail: String
        var version: Int
        var timezone: String
        var approved: Bool
        var notes: String
        var status: ModalityNoticeStatus

        init(code: String, label: String, contactEmail: String, version: Int, timezone: String, approved: Bool, notes: String, status: ModalityNoticeStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.version = version
            self.timezone = timezone
            self.approved = approved
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityNoticeStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ModalityNoticeStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: ModalityNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> ModalityNotice {
            return ModalityNotice(
                code: code,
                label: label,
                contactEmail: contactEmail,
                version: version,
                timezone: timezone,
                approved: approved,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a modality notice in status created.
    static func newModalityNotice(_ code: String, label: String) -> ModalityNotice {
        return ModalityNotice(
            code: code,
            label: label,
            contactEmail: "",
            version: 0,
            timezone: "",
            approved: false,
            notes: "",
            status: ModalityNoticeStatus.created
        )
    }
}
