import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement score is in its life cycle.
    enum StatementScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A statement score. Its code is unique within a tenant.
    final class StatementScore {
        var code: String
        var label: String
        var startsAt: Int
        var encounterID: String
        var margin: Double
        var status: StatementScoreStatus

        init(code: String, label: String, startsAt: Int, encounterID: String, margin: Double, status: StatementScoreStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.encounterID = encounterID
            self.margin = margin
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

        func canMoveTo(_ next: StatementScoreStatus) -> Bool {
            switch status {
            case .new:
                return next == StatementScoreStatus.queued
            case .queued:
                return next == StatementScoreStatus.running || next == StatementScoreStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == StatementScoreStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return ((Double(startsAt) - margin) * 100).rounded() / 100
        }

        func copyValue() -> StatementScore {
            return StatementScore(
                code: code,
                label: label,
                startsAt: startsAt,
                encounterID: encounterID,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a statement score in status new.
    static func newStatementScore(_ code: String, label: String) -> StatementScore {
        return StatementScore(
            code: code,
            label: label,
            startsAt: 0,
            encounterID: "",
            margin: 0.0,
            status: StatementScoreStatus.new
        )
    }
}
