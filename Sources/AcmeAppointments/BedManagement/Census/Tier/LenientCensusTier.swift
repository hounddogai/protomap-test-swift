import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient census tier is in its life cycle.
    enum LenientCensusTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient census tier. Its code is unique within a tenant.
    final class LenientCensusTier {
        var code: String
        var title: String
        var locale: String
        var maximum: Double
        var graceDays: Int
        var status: LenientCensusTierStatus

        init(code: String, title: String, locale: String, maximum: Double, graceDays: Int, status: LenientCensusTierStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.maximum = maximum
            self.graceDays = graceDays
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

        func canMoveTo(_ next: LenientCensusTierStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LenientCensusTierStatus.reopened
            case .inReview:
                return next == LenientCensusTierStatus.resolved || next == LenientCensusTierStatus.archived
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: LenientCensusTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient census tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedValue() -> Double {
            return ((Double(graceDays) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> LenientCensusTier {
            return LenientCensusTier(
                code: code,
                title: title,
                locale: locale,
                maximum: maximum,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient census tier in status open.
    static func newLenientCensusTier(_ code: String, title: String) -> LenientCensusTier {
        return LenientCensusTier(
            code: code,
            title: title,
            locale: "",
            maximum: 0.0,
            graceDays: 0,
            status: LenientCensusTierStatus.`open`
        )
    }
}
