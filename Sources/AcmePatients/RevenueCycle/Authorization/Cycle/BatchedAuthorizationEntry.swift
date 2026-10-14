import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched authorization entry is in its life cycle.
    enum BatchedAuthorizationEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A batched authorization entry. Its code is unique within a tenant.
    final class BatchedAuthorizationEntry {
        var code: String
        var name: String
        var margin: Double
        var refills: Int
        var externalRef: String
        var phone: String
        var status: BatchedAuthorizationEntryStatus

        init(code: String, name: String, margin: Double, refills: Int, externalRef: String, phone: String, status: BatchedAuthorizationEntryStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.refills = refills
            self.externalRef = externalRef
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedAuthorizationEntryStatus) -> Bool {
            switch status {
            case .planned:
                return next == BatchedAuthorizationEntryStatus.inProgress || next == BatchedAuthorizationEntryStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == BatchedAuthorizationEntryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedAuthorizationEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched authorization entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return ((margin + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedAuthorizationEntry {
            return BatchedAuthorizationEntry(
                code: code,
                name: name,
                margin: margin,
                refills: refills,
                externalRef: externalRef,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched authorization entry in status planned.
    static func newBatchedAuthorizationEntry(_ code: String, name: String) -> BatchedAuthorizationEntry {
        return BatchedAuthorizationEntry(
            code: code,
            name: name,
            margin: 0.0,
            refills: 0,
            externalRef: "",
            phone: "",
            status: BatchedAuthorizationEntryStatus.planned
        )
    }
}
