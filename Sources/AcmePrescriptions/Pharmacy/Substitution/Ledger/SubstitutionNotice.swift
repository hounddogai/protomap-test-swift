import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution notice is in its life cycle.
    enum SubstitutionNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One substitution notice, with what the planners need to act on it.
    final class SubstitutionNotice {
        var code: String
        var title: String
        var phone: String
        var label: String
        var locale: String
        var quantity: Int
        var status: SubstitutionNoticeStatus

        init(code: String, title: String, phone: String, label: String, locale: String, quantity: Int, status: SubstitutionNoticeStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.label = label
            self.locale = locale
            self.quantity = quantity
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

        func canMoveTo(_ next: SubstitutionNoticeStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == SubstitutionNoticeStatus.published
            case .published:
                return next == SubstitutionNoticeStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> SubstitutionNotice {
            return SubstitutionNotice(
                code: code,
                title: title,
                phone: phone,
                label: label,
                locale: locale,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a substitution notice in status created.
    static func newSubstitutionNotice(_ code: String, title: String) -> SubstitutionNotice {
        return SubstitutionNotice(
            code: code,
            title: title,
            phone: "",
            label: "",
            locale: "",
            quantity: 0,
            status: SubstitutionNoticeStatus.created
        )
    }
}
