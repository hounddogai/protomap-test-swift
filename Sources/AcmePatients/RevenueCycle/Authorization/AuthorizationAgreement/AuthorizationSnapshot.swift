import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization snapshot is in its life cycle.
    enum AuthorizationSnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A authorization snapshot. Its code is unique within a tenant.
    final class AuthorizationSnapshot {
        var code: String
        var name: String
        var category: String
        var revision: Int
        var bed: String
        var batchSize: Int
        var summary: String
        var status: AuthorizationSnapshotStatus

        init(code: String, name: String, category: String, revision: Int, bed: String, batchSize: Int, summary: String, status: AuthorizationSnapshotStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.revision = revision
            self.bed = bed
            self.batchSize = batchSize
            self.summary = summary
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

        func canMoveTo(_ next: AuthorizationSnapshotStatus) -> Bool {
            switch status {
            case .created:
                return next == AuthorizationSnapshotStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AuthorizationSnapshotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveExposure() -> Double {
            return ((Double(batchSize) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationSnapshot {
            return AuthorizationSnapshot(
                code: code,
                name: name,
                category: category,
                revision: revision,
                bed: bed,
                batchSize: batchSize,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a authorization snapshot in status created.
    static func newAuthorizationSnapshot(_ code: String, name: String) -> AuthorizationSnapshot {
        return AuthorizationSnapshot(
            code: code,
            name: name,
            category: "",
            revision: 0,
            bed: "",
            batchSize: 0,
            summary: "",
            status: AuthorizationSnapshotStatus.created
        )
    }
}
