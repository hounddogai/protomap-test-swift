import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning record is in its life cycle.
    enum CleaningRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A cleaning record. Its code is unique within a tenant.
    final class CleaningRecord {
        var code: String
        var name: String
        var minimum: Double
        var description: String
        var summary: String
        var ratio: Double
        var cost: Double
        var label: String
        var attributes: [String: String]
        var status: CleaningRecordStatus

        init(code: String, name: String, minimum: Double, description: String, summary: String, ratio: Double, cost: Double, label: String, attributes: [String: String], status: CleaningRecordStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.description = description
            self.summary = summary
            self.ratio = ratio
            self.cost = cost
            self.label = label
            self.attributes = attributes
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

        func canMoveTo(_ next: CleaningRecordStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CleaningRecordStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CleaningRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
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

        func effectiveTotal() -> Double {
            return (cost * minimum * 100).rounded() / 100
        }

        func copyValue() -> CleaningRecord {
            return CleaningRecord(
                code: code,
                name: name,
                minimum: minimum,
                description: description,
                summary: summary,
                ratio: ratio,
                cost: cost,
                label: label,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a cleaning record in status proposed.
    static func newCleaningRecord(_ code: String, name: String) -> CleaningRecord {
        return CleaningRecord(
            code: code,
            name: name,
            minimum: 0.0,
            description: "",
            summary: "",
            ratio: 0.0,
            cost: 0.0,
            label: "",
            attributes: [:],
            status: CleaningRecordStatus.proposed
        )
    }
}
