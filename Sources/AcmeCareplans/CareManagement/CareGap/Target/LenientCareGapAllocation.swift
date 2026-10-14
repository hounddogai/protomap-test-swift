import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient care gap allocation is in its life cycle.
    enum LenientCareGapAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One lenient care gap allocation, with what the planners need to act on it.
    final class LenientCareGapAllocation {
        var code: String
        var title: String
        var capacity: Int
        var active: Bool
        var summary: String
        var visitMinutes: Int
        var weight: Double
        var locale: String
        var unit: String
        var status: LenientCareGapAllocationStatus

        init(code: String, title: String, capacity: Int, active: Bool, summary: String, visitMinutes: Int, weight: Double, locale: String, unit: String, status: LenientCareGapAllocationStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.active = active
            self.summary = summary
            self.visitMinutes = visitMinutes
            self.weight = weight
            self.locale = locale
            self.unit = unit
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

        func canMoveTo(_ next: LenientCareGapAllocationStatus) -> Bool {
            switch status {
            case .idle:
                return next == LenientCareGapAllocationStatus.warming
            case .warming:
                return next == LenientCareGapAllocationStatus.draining
            case .ready:
                return next == LenientCareGapAllocationStatus.draining || next == LenientCareGapAllocationStatus.stopped
            case .draining:
                return next == LenientCareGapAllocationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientCareGapAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient care gap allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedValue() -> Double {
            return ((Double(visitMinutes) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> LenientCareGapAllocation {
            return LenientCareGapAllocation(
                code: code,
                title: title,
                capacity: capacity,
                active: active,
                summary: summary,
                visitMinutes: visitMinutes,
                weight: weight,
                locale: locale,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient care gap allocation in status idle.
    static func newLenientCareGapAllocation(_ code: String, title: String) -> LenientCareGapAllocation {
        return LenientCareGapAllocation(
            code: code,
            title: title,
            capacity: 0,
            active: false,
            summary: "",
            visitMinutes: 0,
            weight: 0.0,
            locale: "",
            unit: "",
            status: LenientCareGapAllocationStatus.idle
        )
    }
}
