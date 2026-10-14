import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback care gap entry is in its life cycle.
    enum FallbackCareGapEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback care gap entry as the care gap team keeps it.
    final class FallbackCareGapEntry {
        var code: String
        var title: String
        var acuity: Int
        var windowDays: Int
        var currency: String
        var margin: Double
        var category: String
        var status: FallbackCareGapEntryStatus

        init(code: String, title: String, acuity: Int, windowDays: Int, currency: String, margin: Double, category: String, status: FallbackCareGapEntryStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.windowDays = windowDays
            self.currency = currency
            self.margin = margin
            self.category = category
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

        func canMoveTo(_ next: FallbackCareGapEntryStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackCareGapEntryStatus.stopped
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FallbackCareGapEntryStatus.draining
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

        func moveTo(_ next: FallbackCareGapEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback care gap entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedValue() -> Double {
            return ((Double(windowDays) - margin) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCareGapEntry {
            return FallbackCareGapEntry(
                code: code,
                title: title,
                acuity: acuity,
                windowDays: windowDays,
                currency: currency,
                margin: margin,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback care gap entry in status idle.
    static func newFallbackCareGapEntry(_ code: String, title: String) -> FallbackCareGapEntry {
        return FallbackCareGapEntry(
            code: code,
            title: title,
            acuity: 0,
            windowDays: 0,
            currency: "",
            margin: 0.0,
            category: "",
            status: FallbackCareGapEntryStatus.idle
        )
    }
}
