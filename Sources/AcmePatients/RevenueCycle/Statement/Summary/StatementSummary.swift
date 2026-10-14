import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement summary is in its life cycle.
    enum StatementSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a statement summary and its current status.
    final class StatementSummary {
        var code: String
        var name: String
        var approved: Bool
        var sequence: Int
        var ward: String
        var budget: Double
        var timezone: String
        var expiresAt: Int
        var diagnosisCode: String
        var status: StatementSummaryStatus

        init(code: String, name: String, approved: Bool, sequence: Int, ward: String, budget: Double, timezone: String, expiresAt: Int, diagnosisCode: String, status: StatementSummaryStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.sequence = sequence
            self.ward = ward
            self.budget = budget
            self.timezone = timezone
            self.expiresAt = expiresAt
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: StatementSummaryStatus) -> Bool {
            switch status {
            case .draft:
                return next == StatementSummaryStatus.pending || next == StatementSummaryStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StatementSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netValue() -> Double {
            return ((Double(expiresAt) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> StatementSummary {
            return StatementSummary(
                code: code,
                name: name,
                approved: approved,
                sequence: sequence,
                ward: ward,
                budget: budget,
                timezone: timezone,
                expiresAt: expiresAt,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a statement summary in status draft.
    static func newStatementSummary(_ code: String, name: String) -> StatementSummary {
        return StatementSummary(
            code: code,
            name: name,
            approved: false,
            sequence: 0,
            ward: "",
            budget: 0.0,
            timezone: "",
            expiresAt: 0,
            diagnosisCode: "",
            status: StatementSummaryStatus.draft
        )
    }
}
