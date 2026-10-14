import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive care gap window is in its life cycle.
    enum AdaptiveCareGapWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One adaptive care gap window, with what the planners need to act on it.
    final class AdaptiveCareGapWindow {
        var code: String
        var title: String
        var pinned: Bool
        var locale: String
        var graceDays: Int
        var specialty: String
        var unit: String
        var currency: String
        var rate: Double
        var weight: Double
        var status: AdaptiveCareGapWindowStatus

        init(code: String, title: String, pinned: Bool, locale: String, graceDays: Int, specialty: String, unit: String, currency: String, rate: Double, weight: Double, status: AdaptiveCareGapWindowStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.locale = locale
            self.graceDays = graceDays
            self.specialty = specialty
            self.unit = unit
            self.currency = currency
            self.rate = rate
            self.weight = weight
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

        func canMoveTo(_ next: AdaptiveCareGapWindowStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveCareGapWindowStatus.pending || next == AdaptiveCareGapWindowStatus.suspended
            case .pending:
                return next == AdaptiveCareGapWindowStatus.active || next == AdaptiveCareGapWindowStatus.closed
            case .active:
                return next == AdaptiveCareGapWindowStatus.suspended || next == AdaptiveCareGapWindowStatus.closed
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

        func moveTo(_ next: AdaptiveCareGapWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive care gap window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive care gap window") \(code)"
        }

        func effectiveExposure() -> Double {
            return (rate * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCareGapWindow {
            return AdaptiveCareGapWindow(
                code: code,
                title: title,
                pinned: pinned,
                locale: locale,
                graceDays: graceDays,
                specialty: specialty,
                unit: unit,
                currency: currency,
                rate: rate,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a adaptive care gap window in status draft.
    static func newAdaptiveCareGapWindow(_ code: String, title: String) -> AdaptiveCareGapWindow {
        return AdaptiveCareGapWindow(
            code: code,
            title: title,
            pinned: false,
            locale: "",
            graceDays: 0,
            specialty: "",
            unit: "",
            currency: "",
            rate: 0.0,
            weight: 0.0,
            status: AdaptiveCareGapWindowStatus.draft
        )
    }
}
