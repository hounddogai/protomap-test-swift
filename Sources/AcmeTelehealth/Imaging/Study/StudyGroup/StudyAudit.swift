import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study audit is in its life cycle.
    enum StudyAuditStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a study audit and its current status.
    final class StudyAudit {
        var code: String
        var name: String
        var checksum: String
        var createdAt: Int
        var currency: String
        var status: StudyAuditStatus

        init(code: String, name: String, checksum: String, createdAt: Int, currency: String, status: StudyAuditStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.createdAt = createdAt
            self.currency = currency
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

        func canMoveTo(_ next: StudyAuditStatus) -> Bool {
            switch status {
            case .created:
                return next == StudyAuditStatus.validated || next == StudyAuditStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == StudyAuditStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("study audit") \(code)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> StudyAudit {
            return StudyAudit(
                code: code,
                name: name,
                checksum: checksum,
                createdAt: createdAt,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a study audit in status created.
    static func newStudyAudit(_ code: String, name: String) -> StudyAudit {
        return StudyAudit(
            code: code,
            name: name,
            checksum: "",
            createdAt: 0,
            currency: "",
            status: StudyAuditStatus.created
        )
    }
}
