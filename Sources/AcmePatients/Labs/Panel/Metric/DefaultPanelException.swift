import AcmePlatform
import Foundation

extension Labs {
    /// Where a default panel exception is in its life cycle.
    enum DefaultPanelExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a default panel exception and its current status.
    final class DefaultPanelException {
        var code: String
        var label: String
        var attributes: [String: String]
        var expiresAt: Int
        var margin: Double
        var revision: Int
        var notes: String
        var status: DefaultPanelExceptionStatus

        init(code: String, label: String, attributes: [String: String], expiresAt: Int, margin: Double, revision: Int, notes: String, status: DefaultPanelExceptionStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.expiresAt = expiresAt
            self.margin = margin
            self.revision = revision
            self.notes = notes
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

        func canMoveTo(_ next: DefaultPanelExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DefaultPanelExceptionStatus.approved || next == DefaultPanelExceptionStatus.rejected
            case .approved:
                return next == DefaultPanelExceptionStatus.rejected || next == DefaultPanelExceptionStatus.withdrawn
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

        func moveTo(_ next: DefaultPanelExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default panel exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("default panel exception") \(code)"
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

        func weightedValue() -> Double {
            return (Double(expiresAt) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> DefaultPanelException {
            return DefaultPanelException(
                code: code,
                label: label,
                attributes: attributes,
                expiresAt: expiresAt,
                margin: margin,
                revision: revision,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default panel exception in status proposed.
    static func newDefaultPanelException(_ code: String, label: String) -> DefaultPanelException {
        return DefaultPanelException(
            code: code,
            label: label,
            attributes: [:],
            expiresAt: 0,
            margin: 0.0,
            revision: 0,
            notes: "",
            status: DefaultPanelExceptionStatus.proposed
        )
    }
}
