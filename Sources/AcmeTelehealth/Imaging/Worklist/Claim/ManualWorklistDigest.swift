import AcmePlatform
import Foundation

extension Imaging {
    /// Where a manual worklist digest is in its life cycle.
    enum ManualWorklistDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A manual worklist digest as the worklist team keeps it.
    final class ManualWorklistDigest {
        var code: String
        var name: String
        var phone: String
        var budget: Double
        var durationMinutes: Int
        var title: String
        var margin: Double
        var locale: String
        var status: ManualWorklistDigestStatus

        init(code: String, name: String, phone: String, budget: Double, durationMinutes: Int, title: String, margin: Double, locale: String, status: ManualWorklistDigestStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.title = title
            self.margin = margin
            self.locale = locale
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

        func canMoveTo(_ next: ManualWorklistDigestStatus) -> Bool {
            switch status {
            case .planned:
                return next == ManualWorklistDigestStatus.scheduled || next == ManualWorklistDigestStatus.completed
            case .scheduled:
                return next == ManualWorklistDigestStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ManualWorklistDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualWorklistDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual worklist digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual worklist digest") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(durationMinutes) + margin) * 100).rounded() / 100
        }

        func copyValue() -> ManualWorklistDigest {
            return ManualWorklistDigest(
                code: code,
                name: name,
                phone: phone,
                budget: budget,
                durationMinutes: durationMinutes,
                title: title,
                margin: margin,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a manual worklist digest in status planned.
    static func newManualWorklistDigest(_ code: String, name: String) -> ManualWorklistDigest {
        return ManualWorklistDigest(
            code: code,
            name: name,
            phone: "",
            budget: 0.0,
            durationMinutes: 0,
            title: "",
            margin: 0.0,
            locale: "",
            status: ManualWorklistDigestStatus.planned
        )
    }
}
