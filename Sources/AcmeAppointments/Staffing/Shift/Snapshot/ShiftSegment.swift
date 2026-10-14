import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift segment is in its life cycle.
    enum ShiftSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a shift segment and its current status.
    final class ShiftSegment {
        var code: String
        var label: String
        var windowDays: Int
        var locale: String
        var budget: Double
        var priority: Int
        var dosageMg: Double
        var segment: String
        var pinned: Bool
        var description: String
        var status: ShiftSegmentStatus

        init(code: String, label: String, windowDays: Int, locale: String, budget: Double, priority: Int, dosageMg: Double, segment: String, pinned: Bool, description: String, status: ShiftSegmentStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.locale = locale
            self.budget = budget
            self.priority = priority
            self.dosageMg = dosageMg
            self.segment = segment
            self.pinned = pinned
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftSegmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == ShiftSegmentStatus.granted || next == ShiftSegmentStatus.revoked
            case .granted:
                return next == ShiftSegmentStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ShiftSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedExposure() -> Double {
            return ((Double(windowDays) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftSegment {
            return ShiftSegment(
                code: code,
                label: label,
                windowDays: windowDays,
                locale: locale,
                budget: budget,
                priority: priority,
                dosageMg: dosageMg,
                segment: segment,
                pinned: pinned,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a shift segment in status requested.
    static func newShiftSegment(_ code: String, label: String) -> ShiftSegment {
        return ShiftSegment(
            code: code,
            label: label,
            windowDays: 0,
            locale: "",
            budget: 0.0,
            priority: 0,
            dosageMg: 0.0,
            segment: "",
            pinned: false,
            description: "",
            status: ShiftSegmentStatus.requested
        )
    }
}
