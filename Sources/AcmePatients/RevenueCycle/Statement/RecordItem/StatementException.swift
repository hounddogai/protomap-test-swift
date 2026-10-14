import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement exception is in its life cycle.
    enum StatementExceptionStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A statement exception as the statement team keeps it.
    final class StatementException {
        var code: String
        var label: String
        var weight: Double
        var score: Double
        var name: String
        var expiresAt: Int
        var patientRef: String
        var status: StatementExceptionStatus

        init(code: String, label: String, weight: Double, score: Double, name: String, expiresAt: Int, patientRef: String, status: StatementExceptionStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.score = score
            self.name = name
            self.expiresAt = expiresAt
            self.patientRef = patientRef
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

        func canMoveTo(_ next: StatementExceptionStatus) -> Bool {
            switch status {
            case .draft:
                return next == StatementExceptionStatus.pending || next == StatementExceptionStatus.closed
            case .pending:
                return next == StatementExceptionStatus.active
            case .active:
                return next == StatementExceptionStatus.suspended || next == StatementExceptionStatus.closed
            case .suspended:
                return next == StatementExceptionStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(expiresAt) + score) * 100).rounded() / 100
        }

        func copyValue() -> StatementException {
            return StatementException(
                code: code,
                label: label,
                weight: weight,
                score: score,
                name: name,
                expiresAt: expiresAt,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a statement exception in status draft.
    static func newStatementException(_ code: String, label: String) -> StatementException {
        return StatementException(
            code: code,
            label: label,
            weight: 0.0,
            score: 0.0,
            name: "",
            expiresAt: 0,
            patientRef: "",
            status: StatementExceptionStatus.draft
        )
    }
}
