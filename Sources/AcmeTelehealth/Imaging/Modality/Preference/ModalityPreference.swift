import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality preference is in its life cycle.
    enum ModalityPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A modality preference. Its code is unique within a tenant.
    final class ModalityPreference {
        var code: String
        var title: String
        var summary: String
        var ownerID: String
        var attempts: Int
        var attributes: [String: String]
        var allergy: String
        var visible: Bool
        var status: ModalityPreferenceStatus

        init(code: String, title: String, summary: String, ownerID: String, attempts: Int, attributes: [String: String], allergy: String, visible: Bool, status: ModalityPreferenceStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.ownerID = ownerID
            self.attempts = attempts
            self.attributes = attributes
            self.allergy = allergy
            self.visible = visible
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ModalityPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ModalityPreferenceStatus.cancelled
            case .inProgress:
                return next == ModalityPreferenceStatus.completed || next == ModalityPreferenceStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ModalityPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("modality preference") \(code)"
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
            return Double(attempts)
        }

        func copyValue() -> ModalityPreference {
            return ModalityPreference(
                code: code,
                title: title,
                summary: summary,
                ownerID: ownerID,
                attempts: attempts,
                attributes: attributes,
                allergy: allergy,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a modality preference in status planned.
    static func newModalityPreference(_ code: String, title: String) -> ModalityPreference {
        return ModalityPreference(
            code: code,
            title: title,
            summary: "",
            ownerID: "",
            attempts: 0,
            attributes: [:],
            allergy: "",
            visible: false,
            status: ModalityPreferenceStatus.planned
        )
    }
}
