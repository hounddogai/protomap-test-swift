import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance tier is in its life cycle.
    enum RemittanceTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A remittance tier. Its code is unique within a tenant.
    final class RemittanceTier {
        var code: String
        var title: String
        var clinicianID: String
        var refills: Int
        var visitMinutes: Int
        var archived: Bool
        var createdAt: Int
        var revision: Int
        var status: RemittanceTierStatus

        init(code: String, title: String, clinicianID: String, refills: Int, visitMinutes: Int, archived: Bool, createdAt: Int, revision: Int, status: RemittanceTierStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.refills = refills
            self.visitMinutes = visitMinutes
            self.archived = archived
            self.createdAt = createdAt
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

        func canMoveTo(_ next: RemittanceTierStatus) -> Bool {
            switch status {
            case .draft:
                return next == RemittanceTierStatus.pending || next == RemittanceTierStatus.closed
            case .pending:
                return next == RemittanceTierStatus.suspended
            case .active:
                switch next {
                case .suspended:
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

        func moveTo(_ next: RemittanceTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netValue() -> Double {
            return ((Double(refills) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceTier {
            return RemittanceTier(
                code: code,
                title: title,
                clinicianID: clinicianID,
                refills: refills,
                visitMinutes: visitMinutes,
                archived: archived,
                createdAt: createdAt,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a remittance tier in status draft.
    static func newRemittanceTier(_ code: String, title: String) -> RemittanceTier {
        return RemittanceTier(
            code: code,
            title: title,
            clinicianID: "",
            refills: 0,
            visitMinutes: 0,
            archived: false,
            createdAt: 0,
            revision: 0,
            status: RemittanceTierStatus.draft
        )
    }
}
