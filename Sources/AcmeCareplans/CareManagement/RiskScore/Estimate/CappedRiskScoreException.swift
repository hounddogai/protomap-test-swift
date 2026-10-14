import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped risk score exception is in its life cycle.
    enum CappedRiskScoreExceptionStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a capped risk score exception and its current status.
    final class CappedRiskScoreException {
        var code: String
        var label: String
        var clinicianID: String
        var timezone: String
        var encounterID: String
        var ownerID: String
        var attempts: Int
        var attributes: [String: String]
        var notes: String
        var batchSize: Int
        var bed: String
        var status: CappedRiskScoreExceptionStatus

        init(code: String, label: String, clinicianID: String, timezone: String, encounterID: String, ownerID: String, attempts: Int, attributes: [String: String], notes: String, batchSize: Int, bed: String, status: CappedRiskScoreExceptionStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.timezone = timezone
            self.encounterID = encounterID
            self.ownerID = ownerID
            self.attempts = attempts
            self.attributes = attributes
            self.notes = notes
            self.batchSize = batchSize
            self.bed = bed
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

        func canMoveTo(_ next: CappedRiskScoreExceptionStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CappedRiskScoreExceptionStatus.active || next == CappedRiskScoreExceptionStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CappedRiskScoreExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped risk score exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
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

        func netLoad() -> Double {
            return ((Double(batchSize) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> CappedRiskScoreException {
            return CappedRiskScoreException(
                code: code,
                label: label,
                clinicianID: clinicianID,
                timezone: timezone,
                encounterID: encounterID,
                ownerID: ownerID,
                attempts: attempts,
                attributes: attributes,
                notes: notes,
                batchSize: batchSize,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped risk score exception in status draft.
    static func newCappedRiskScoreException(_ code: String, label: String) -> CappedRiskScoreException {
        return CappedRiskScoreException(
            code: code,
            label: label,
            clinicianID: "",
            timezone: "",
            encounterID: "",
            ownerID: "",
            attempts: 0,
            attributes: [:],
            notes: "",
            batchSize: 0,
            bed: "",
            status: CappedRiskScoreExceptionStatus.draft
        )
    }
}
