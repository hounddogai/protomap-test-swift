import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive outreach bundle is in its life cycle.
    enum AdaptiveOutreachBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive outreach bundle. Its code is unique within a tenant.
    final class AdaptiveOutreachBundle {
        var code: String
        var title: String
        var revision: Int
        var encounterID: String
        var attempts: Int
        var status: AdaptiveOutreachBundleStatus

        init(code: String, title: String, revision: Int, encounterID: String, attempts: Int, status: AdaptiveOutreachBundleStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.encounterID = encounterID
            self.attempts = attempts
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

        func canMoveTo(_ next: AdaptiveOutreachBundleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AdaptiveOutreachBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive outreach bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return (Double(revision) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveOutreachBundle {
            return AdaptiveOutreachBundle(
                code: code,
                title: title,
                revision: revision,
                encounterID: encounterID,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive outreach bundle in status open.
    static func newAdaptiveOutreachBundle(_ code: String, title: String) -> AdaptiveOutreachBundle {
        return AdaptiveOutreachBundle(
            code: code,
            title: title,
            revision: 0,
            encounterID: "",
            attempts: 0,
            status: AdaptiveOutreachBundleStatus.`open`
        )
    }
}
