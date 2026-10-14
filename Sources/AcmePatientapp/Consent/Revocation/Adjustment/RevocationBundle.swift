import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation bundle is in its life cycle.
    enum RevocationBundleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A revocation bundle. Its code is unique within a tenant.
    final class RevocationBundle {
        var code: String
        var title: String
        var encounterID: String
        var ratio: Double
        var archived: Bool
        var segment: String
        var status: RevocationBundleStatus

        init(code: String, title: String, encounterID: String, ratio: Double, archived: Bool, segment: String, status: RevocationBundleStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.ratio = ratio
            self.archived = archived
            self.segment = segment
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

        func canMoveTo(_ next: RevocationBundleStatus) -> Bool {
            switch status {
            case .new:
                return next == RevocationBundleStatus.queued || next == RevocationBundleStatus.failed
            case .queued:
                return next == RevocationBundleStatus.running
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RevocationBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return ratio
        }

        func copyValue() -> RevocationBundle {
            return RevocationBundle(
                code: code,
                title: title,
                encounterID: encounterID,
                ratio: ratio,
                archived: archived,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a revocation bundle in status new.
    static func newRevocationBundle(_ code: String, title: String) -> RevocationBundle {
        return RevocationBundle(
            code: code,
            title: title,
            encounterID: "",
            ratio: 0.0,
            archived: false,
            segment: "",
            status: RevocationBundleStatus.new
        )
    }
}
