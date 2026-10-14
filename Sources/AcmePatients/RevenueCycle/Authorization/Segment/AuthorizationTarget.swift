import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization target is in its life cycle.
    enum AuthorizationTargetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a authorization target and its current status.
    final class AuthorizationTarget {
        var code: String
        var title: String
        var label: String
        var bed: String
        var archived: Bool
        var margin: Double
        var status: AuthorizationTargetStatus

        init(code: String, title: String, label: String, bed: String, archived: Bool, margin: Double, status: AuthorizationTargetStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.bed = bed
            self.archived = archived
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

        func canMoveTo(_ next: AuthorizationTargetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AuthorizationTargetStatus.running || next == AuthorizationTargetStatus.done
            case .running:
                return next == AuthorizationTargetStatus.failed
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

        func moveTo(_ next: AuthorizationTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> AuthorizationTarget {
            return AuthorizationTarget(
                code: code,
                title: title,
                label: label,
                bed: bed,
                archived: archived,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a authorization target in status new.
    static func newAuthorizationTarget(_ code: String, title: String) -> AuthorizationTarget {
        return AuthorizationTarget(
            code: code,
            title: title,
            label: "",
            bed: "",
            archived: false,
            margin: 0.0,
            status: AuthorizationTargetStatus.new
        )
    }
}
