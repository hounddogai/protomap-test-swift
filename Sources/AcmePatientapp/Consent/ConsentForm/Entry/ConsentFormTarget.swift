import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form target is in its life cycle.
    enum ConsentFormTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a consent form target and its current status.
    final class ConsentFormTarget {
        var code: String
        var name: String
        var locale: String
        var title: String
        var floorValue: Double
        var status: ConsentFormTargetStatus

        init(code: String, name: String, locale: String, title: String, floorValue: Double, status: ConsentFormTargetStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.title = title
            self.floorValue = floorValue
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

        func canMoveTo(_ next: ConsentFormTargetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ConsentFormTargetStatus.suspended || next == ConsentFormTargetStatus.closed
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

        func moveTo(_ next: ConsentFormTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> ConsentFormTarget {
            return ConsentFormTarget(
                code: code,
                name: name,
                locale: locale,
                title: title,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a consent form target in status draft.
    static func newConsentFormTarget(_ code: String, name: String) -> ConsentFormTarget {
        return ConsentFormTarget(
            code: code,
            name: name,
            locale: "",
            title: "",
            floorValue: 0.0,
            status: ConsentFormTargetStatus.draft
        )
    }
}
