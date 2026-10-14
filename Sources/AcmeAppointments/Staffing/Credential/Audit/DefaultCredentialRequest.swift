import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default credential request is in its life cycle.
    enum DefaultCredentialRequestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default credential request. Its code is unique within a tenant.
    final class DefaultCredentialRequest {
        var code: String
        var title: String
        var attributes: [String: String]
        var visitMinutes: Int
        var reviewer: String
        var label: String
        var diagnosisCode: String
        var durationMinutes: Int
        var status: DefaultCredentialRequestStatus

        init(code: String, title: String, attributes: [String: String], visitMinutes: Int, reviewer: String, label: String, diagnosisCode: String, durationMinutes: Int, status: DefaultCredentialRequestStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.visitMinutes = visitMinutes
            self.reviewer = reviewer
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: DefaultCredentialRequestStatus) -> Bool {
            switch status {
            case .planned:
                return next == DefaultCredentialRequestStatus.completed
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == DefaultCredentialRequestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultCredentialRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default credential request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
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

        func projectedTotal() -> Double {
            return (Double(durationMinutes) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCredentialRequest {
            return DefaultCredentialRequest(
                code: code,
                title: title,
                attributes: attributes,
                visitMinutes: visitMinutes,
                reviewer: reviewer,
                label: label,
                diagnosisCode: diagnosisCode,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default credential request in status planned.
    static func newDefaultCredentialRequest(_ code: String, title: String) -> DefaultCredentialRequest {
        return DefaultCredentialRequest(
            code: code,
            title: title,
            attributes: [:],
            visitMinutes: 0,
            reviewer: "",
            label: "",
            diagnosisCode: "",
            durationMinutes: 0,
            status: DefaultCredentialRequestStatus.planned
        )
    }
}
