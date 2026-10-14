import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement assignment is in its life cycle.
    enum StatementAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a statement assignment and its current status.
    final class StatementAssignment {
        var code: String
        var label: String
        var allergy: String
        var expiresAt: Int
        var ceiling: Double
        var title: String
        var graceDays: Int
        var limit: Int
        var attributes: [String: String]
        var encounterID: String
        var payer: String
        var status: StatementAssignmentStatus

        init(code: String, label: String, allergy: String, expiresAt: Int, ceiling: Double, title: String, graceDays: Int, limit: Int, attributes: [String: String], encounterID: String, payer: String, status: StatementAssignmentStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.expiresAt = expiresAt
            self.ceiling = ceiling
            self.title = title
            self.graceDays = graceDays
            self.limit = limit
            self.attributes = attributes
            self.encounterID = encounterID
            self.payer = payer
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

        func canMoveTo(_ next: StatementAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == StatementAssignmentStatus.active || next == StatementAssignmentStatus.suspended
            case .pending:
                return next == StatementAssignmentStatus.active
            case .active:
                return next == StatementAssignmentStatus.closed
            case .suspended:
                return next == StatementAssignmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("statement assignment") \(code)"
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
            return ((Double(graceDays) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> StatementAssignment {
            return StatementAssignment(
                code: code,
                label: label,
                allergy: allergy,
                expiresAt: expiresAt,
                ceiling: ceiling,
                title: title,
                graceDays: graceDays,
                limit: limit,
                attributes: attributes,
                encounterID: encounterID,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a statement assignment in status draft.
    static func newStatementAssignment(_ code: String, label: String) -> StatementAssignment {
        return StatementAssignment(
            code: code,
            label: label,
            allergy: "",
            expiresAt: 0,
            ceiling: 0.0,
            title: "",
            graceDays: 0,
            limit: 0,
            attributes: [:],
            encounterID: "",
            payer: "",
            status: StatementAssignmentStatus.draft
        )
    }
}
