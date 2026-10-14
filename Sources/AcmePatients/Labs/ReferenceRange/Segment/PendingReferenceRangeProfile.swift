import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending reference range profile is in its life cycle.
    enum PendingReferenceRangeProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending reference range profile. Its code is unique within a tenant.
    final class PendingReferenceRangeProfile {
        var code: String
        var label: String
        var visible: Bool
        var revision: Int
        var createdAt: Int
        var status: PendingReferenceRangeProfileStatus

        init(code: String, label: String, visible: Bool, revision: Int, createdAt: Int, status: PendingReferenceRangeProfileStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.revision = revision
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingReferenceRangeProfileStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == PendingReferenceRangeProfileStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PendingReferenceRangeProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending reference range profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("pending reference range profile") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(createdAt) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> PendingReferenceRangeProfile {
            return PendingReferenceRangeProfile(
                code: code,
                label: label,
                visible: visible,
                revision: revision,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending reference range profile in status open.
    static func newPendingReferenceRangeProfile(_ code: String, label: String) -> PendingReferenceRangeProfile {
        return PendingReferenceRangeProfile(
            code: code,
            label: label,
            visible: false,
            revision: 0,
            createdAt: 0,
            status: PendingReferenceRangeProfileStatus.`open`
        )
    }
}
