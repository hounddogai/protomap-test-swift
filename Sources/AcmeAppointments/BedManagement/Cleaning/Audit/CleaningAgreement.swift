import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning agreement is in its life cycle.
    enum CleaningAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A cleaning agreement as the cleaning team keeps it.
    final class CleaningAgreement {
        var code: String
        var name: String
        var createdAt: Int
        var reviewer: String
        var revision: Int
        var status: CleaningAgreementStatus

        init(code: String, name: String, createdAt: Int, reviewer: String, revision: Int, status: CleaningAgreementStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.reviewer = reviewer
            self.revision = revision
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

        func canMoveTo(_ next: CleaningAgreementStatus) -> Bool {
            switch status {
            case .draft:
                return next == CleaningAgreementStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CleaningAgreementStatus.suspended
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

        func moveTo(_ next: CleaningAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedValue() -> Double {
            return ((Double(createdAt) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> CleaningAgreement {
            return CleaningAgreement(
                code: code,
                name: name,
                createdAt: createdAt,
                reviewer: reviewer,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a cleaning agreement in status draft.
    static func newCleaningAgreement(_ code: String, name: String) -> CleaningAgreement {
        return CleaningAgreement(
            code: code,
            name: name,
            createdAt: 0,
            reviewer: "",
            revision: 0,
            status: CleaningAgreementStatus.draft
        )
    }
}
