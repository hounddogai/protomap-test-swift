import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall assignment is in its life cycle.
    enum RecallAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A recall assignment as the recall team keeps it.
    final class RecallAssignment {
        var code: String
        var label: String
        var amount: Double
        var payer: String
        var ownerID: String
        var encounterID: String
        var attributes: [String: String]
        var summary: String
        var diagnosisCode: String
        var startsAt: Int
        var unit: String
        var status: RecallAssignmentStatus

        init(code: String, label: String, amount: Double, payer: String, ownerID: String, encounterID: String, attributes: [String: String], summary: String, diagnosisCode: String, startsAt: Int, unit: String, status: RecallAssignmentStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.payer = payer
            self.ownerID = ownerID
            self.encounterID = encounterID
            self.attributes = attributes
            self.summary = summary
            self.diagnosisCode = diagnosisCode
            self.startsAt = startsAt
            self.unit = unit
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

        func canMoveTo(_ next: RecallAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RecallAssignmentStatus.approved || next == RecallAssignmentStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RecallAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func projectedVolume() -> Double {
            return ((Double(startsAt) + amount) * 100).rounded() / 100
        }

        func copyValue() -> RecallAssignment {
            return RecallAssignment(
                code: code,
                label: label,
                amount: amount,
                payer: payer,
                ownerID: ownerID,
                encounterID: encounterID,
                attributes: attributes,
                summary: summary,
                diagnosisCode: diagnosisCode,
                startsAt: startsAt,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a recall assignment in status proposed.
    static func newRecallAssignment(_ code: String, label: String) -> RecallAssignment {
        return RecallAssignment(
            code: code,
            label: label,
            amount: 0.0,
            payer: "",
            ownerID: "",
            encounterID: "",
            attributes: [:],
            summary: "",
            diagnosisCode: "",
            startsAt: 0,
            unit: "",
            status: RecallAssignmentStatus.proposed
        )
    }
}
