import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual modality entry is in its life cycle.
    enum ManualModalityEntryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One manual modality entry, with what the planners need to act on it.
    final class ManualModalityEntry {
        var code: String
        var label: String
        var diagnosisCode: String
        var startsAt: Int
        var title: String
        var attributes: [String: String]
        var contactEmail: String
        var status: ManualModalityEntryStatus

        init(code: String, label: String, diagnosisCode: String, startsAt: Int, title: String, attributes: [String: String], contactEmail: String, status: ManualModalityEntryStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.startsAt = startsAt
            self.title = title
            self.attributes = attributes
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ManualModalityEntryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ManualModalityEntryStatus.published || next == ManualModalityEntryStatus.retired
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

        func moveTo(_ next: ManualModalityEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual modality entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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
            return Double(startsAt)
        }

        func copyValue() -> ManualModalityEntry {
            return ManualModalityEntry(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                startsAt: startsAt,
                title: title,
                attributes: attributes,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual modality entry in status created.
    static func newManualModalityEntry(_ code: String, label: String) -> ManualModalityEntry {
        return ManualModalityEntry(
            code: code,
            label: label,
            diagnosisCode: "",
            startsAt: 0,
            title: "",
            attributes: [:],
            contactEmail: "",
            status: ManualModalityEntryStatus.created
        )
    }
}
