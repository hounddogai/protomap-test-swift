import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual courier entry is in its life cycle.
    enum ManualCourierEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual courier entry. Its code is unique within a tenant.
    final class ManualCourierEntry {
        var code: String
        var name: String
        var description: String
        var attributes: [String: String]
        var externalRef: String
        var score: Double
        var status: ManualCourierEntryStatus

        init(code: String, name: String, description: String, attributes: [String: String], externalRef: String, score: Double, status: ManualCourierEntryStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.attributes = attributes
            self.externalRef = externalRef
            self.score = score
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

        func canMoveTo(_ next: ManualCourierEntryStatus) -> Bool {
            switch status {
            case .draft:
                return next == ManualCourierEntryStatus.closed
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ManualCourierEntryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCourierEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual courier entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
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
            return score
        }

        func copyValue() -> ManualCourierEntry {
            return ManualCourierEntry(
                code: code,
                name: name,
                description: description,
                attributes: attributes,
                externalRef: externalRef,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual courier entry in status draft.
    static func newManualCourierEntry(_ code: String, name: String) -> ManualCourierEntry {
        return ManualCourierEntry(
            code: code,
            name: name,
            description: "",
            attributes: [:],
            externalRef: "",
            score: 0.0,
            status: ManualCourierEntryStatus.draft
        )
    }
}
