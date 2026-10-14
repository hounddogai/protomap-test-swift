import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge rollup is in its life cycle.
    enum ChargeRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A charge rollup as the charge team keeps it.
    final class ChargeRollup {
        var code: String
        var name: String
        var maximum: Double
        var score: Double
        var diagnosisCode: String
        var label: String
        var approved: Bool
        var status: ChargeRollupStatus

        init(code: String, name: String, maximum: Double, score: Double, diagnosisCode: String, label: String, approved: Bool, status: ChargeRollupStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.score = score
            self.diagnosisCode = diagnosisCode
            self.label = label
            self.approved = approved
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

        func canMoveTo(_ next: ChargeRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == ChargeRollupStatus.active || next == ChargeRollupStatus.closed
            case .pending:
                return next == ChargeRollupStatus.suspended
            case .active:
                return next == ChargeRollupStatus.closed
            case .suspended:
                return next == ChargeRollupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func effectiveTotal() -> Double {
            return (score * maximum * 100).rounded() / 100
        }

        func copyValue() -> ChargeRollup {
            return ChargeRollup(
                code: code,
                name: name,
                maximum: maximum,
                score: score,
                diagnosisCode: diagnosisCode,
                label: label,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a charge rollup in status draft.
    static func newChargeRollup(_ code: String, name: String) -> ChargeRollup {
        return ChargeRollup(
            code: code,
            name: name,
            maximum: 0.0,
            score: 0.0,
            diagnosisCode: "",
            label: "",
            approved: false,
            status: ChargeRollupStatus.draft
        )
    }
}
