import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff checkpoint is in its life cycle.
    enum HandoffCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A handoff checkpoint as the handoff team keeps it.
    final class HandoffCheckpoint {
        var code: String
        var title: String
        var graceDays: Int
        var expiresAt: Int
        var diagnosisCode: String
        var patientRef: String
        var contactEmail: String
        var attributes: [String: String]
        var externalRef: String
        var status: HandoffCheckpointStatus

        init(code: String, title: String, graceDays: Int, expiresAt: Int, diagnosisCode: String, patientRef: String, contactEmail: String, attributes: [String: String], externalRef: String, status: HandoffCheckpointStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.expiresAt = expiresAt
            self.diagnosisCode = diagnosisCode
            self.patientRef = patientRef
            self.contactEmail = contactEmail
            self.attributes = attributes
            self.externalRef = externalRef
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

        func canMoveTo(_ next: HandoffCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == HandoffCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func effectiveVolume() -> Double {
            return ((Double(expiresAt) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> HandoffCheckpoint {
            return HandoffCheckpoint(
                code: code,
                title: title,
                graceDays: graceDays,
                expiresAt: expiresAt,
                diagnosisCode: diagnosisCode,
                patientRef: patientRef,
                contactEmail: contactEmail,
                attributes: attributes,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a handoff checkpoint in status planned.
    static func newHandoffCheckpoint(_ code: String, title: String) -> HandoffCheckpoint {
        return HandoffCheckpoint(
            code: code,
            title: title,
            graceDays: 0,
            expiresAt: 0,
            diagnosisCode: "",
            patientRef: "",
            contactEmail: "",
            attributes: [:],
            externalRef: "",
            status: HandoffCheckpointStatus.planned
        )
    }
}
