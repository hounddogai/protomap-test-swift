import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement estimate is in its life cycle.
    enum StatementEstimateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a statement estimate and its current status.
    final class StatementEstimate {
        var code: String
        var label: String
        var archived: Bool
        var facility: String
        var priority: Int
        var diagnosisCode: String
        var expiresAt: Int
        var status: StatementEstimateStatus

        init(code: String, label: String, archived: Bool, facility: String, priority: Int, diagnosisCode: String, expiresAt: Int, status: StatementEstimateStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.facility = facility
            self.priority = priority
            self.diagnosisCode = diagnosisCode
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StatementEstimateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == StatementEstimateStatus.failed
            case .running:
                return next == StatementEstimateStatus.done
            case .done:
                return next == StatementEstimateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("statement estimate") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(priority) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> StatementEstimate {
            return StatementEstimate(
                code: code,
                label: label,
                archived: archived,
                facility: facility,
                priority: priority,
                diagnosisCode: diagnosisCode,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a statement estimate in status new.
    static func newStatementEstimate(_ code: String, label: String) -> StatementEstimate {
        return StatementEstimate(
            code: code,
            label: label,
            archived: false,
            facility: "",
            priority: 0,
            diagnosisCode: "",
            expiresAt: 0,
            status: StatementEstimateStatus.new
        )
    }
}
