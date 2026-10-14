import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal bundle is in its life cycle.
    enum GoalBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A goal bundle. Its code is unique within a tenant.
    final class GoalBundle {
        var code: String
        var title: String
        var endsAt: Int
        var procedureCode: String
        var margin: Double
        var region: String
        var expiresAt: Int
        var externalRef: String
        var locale: String
        var status: GoalBundleStatus

        init(code: String, title: String, endsAt: Int, procedureCode: String, margin: Double, region: String, expiresAt: Int, externalRef: String, locale: String, status: GoalBundleStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.procedureCode = procedureCode
            self.margin = margin
            self.region = region
            self.expiresAt = expiresAt
            self.externalRef = externalRef
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GoalBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == GoalBundleStatus.draining || next == GoalBundleStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: GoalBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(endsAt) + margin) * 100).rounded() / 100
        }

        func copyValue() -> GoalBundle {
            return GoalBundle(
                code: code,
                title: title,
                endsAt: endsAt,
                procedureCode: procedureCode,
                margin: margin,
                region: region,
                expiresAt: expiresAt,
                externalRef: externalRef,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a goal bundle in status idle.
    static func newGoalBundle(_ code: String, title: String) -> GoalBundle {
        return GoalBundle(
            code: code,
            title: title,
            endsAt: 0,
            procedureCode: "",
            margin: 0.0,
            region: "",
            expiresAt: 0,
            externalRef: "",
            locale: "",
            status: GoalBundleStatus.idle
        )
    }
}
