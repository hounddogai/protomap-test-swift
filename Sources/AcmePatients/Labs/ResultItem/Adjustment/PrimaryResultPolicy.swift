import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary result policy is in its life cycle.
    enum PrimaryResultPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary result policy as the result team keeps it.
    final class PrimaryResultPolicy {
        var code: String
        var title: String
        var locale: String
        var bed: String
        var visible: Bool
        var description: String
        var endsAt: Int
        var active: Bool
        var status: PrimaryResultPolicyStatus

        init(code: String, title: String, locale: String, bed: String, visible: Bool, description: String, endsAt: Int, active: Bool, status: PrimaryResultPolicyStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.bed = bed
            self.visible = visible
            self.description = description
            self.endsAt = endsAt
            self.active = active
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

        func canMoveTo(_ next: PrimaryResultPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == PrimaryResultPolicyStatus.resolved
            case .resolved:
                switch next {
                case .reopened:
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

        func moveTo(_ next: PrimaryResultPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary result policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> PrimaryResultPolicy {
            return PrimaryResultPolicy(
                code: code,
                title: title,
                locale: locale,
                bed: bed,
                visible: visible,
                description: description,
                endsAt: endsAt,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a primary result policy in status open.
    static func newPrimaryResultPolicy(_ code: String, title: String) -> PrimaryResultPolicy {
        return PrimaryResultPolicy(
            code: code,
            title: title,
            locale: "",
            bed: "",
            visible: false,
            description: "",
            endsAt: 0,
            active: false,
            status: PrimaryResultPolicyStatus.`open`
        )
    }
}
