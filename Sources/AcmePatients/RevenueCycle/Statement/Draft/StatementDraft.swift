import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement draft is in its life cycle.
    enum StatementDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A statement draft as the statement team keeps it.
    final class StatementDraft {
        var code: String
        var name: String
        var patientRef: String
        var floorValue: Double
        var attributes: [String: String]
        var dosageMg: Double
        var status: StatementDraftStatus

        init(code: String, name: String, patientRef: String, floorValue: Double, attributes: [String: String], dosageMg: Double, status: StatementDraftStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.floorValue = floorValue
            self.attributes = attributes
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: StatementDraftStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == StatementDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func adjustedVolume() -> Double {
            return ((floorValue + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> StatementDraft {
            return StatementDraft(
                code: code,
                name: name,
                patientRef: patientRef,
                floorValue: floorValue,
                attributes: attributes,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a statement draft in status created.
    static func newStatementDraft(_ code: String, name: String) -> StatementDraft {
        return StatementDraft(
            code: code,
            name: name,
            patientRef: "",
            floorValue: 0.0,
            attributes: [:],
            dosageMg: 0.0,
            status: StatementDraftStatus.created
        )
    }
}
