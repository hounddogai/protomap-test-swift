import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional overtime segment is in its life cycle.
    enum RegionalOvertimeSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a regional overtime segment and its current status.
    final class RegionalOvertimeSegment {
        var code: String
        var label: String
        var description: String
        var checksum: String
        var graceDays: Int
        var durationMinutes: Int
        var cost: Double
        var locale: String
        var ceiling: Double
        var category: String
        var status: RegionalOvertimeSegmentStatus

        init(code: String, label: String, description: String, checksum: String, graceDays: Int, durationMinutes: Int, cost: Double, locale: String, ceiling: Double, category: String, status: RegionalOvertimeSegmentStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.checksum = checksum
            self.graceDays = graceDays
            self.durationMinutes = durationMinutes
            self.cost = cost
            self.locale = locale
            self.ceiling = ceiling
            self.category = category
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

        func canMoveTo(_ next: RegionalOvertimeSegmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RegionalOvertimeSegmentStatus.published
            case .published:
                return next == RegionalOvertimeSegmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalOvertimeSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional overtime segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("regional overtime segment") \(code)"
        }

        func adjustedValue() -> Double {
            return ((ceiling - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalOvertimeSegment {
            return RegionalOvertimeSegment(
                code: code,
                label: label,
                description: description,
                checksum: checksum,
                graceDays: graceDays,
                durationMinutes: durationMinutes,
                cost: cost,
                locale: locale,
                ceiling: ceiling,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional overtime segment in status created.
    static func newRegionalOvertimeSegment(_ code: String, label: String) -> RegionalOvertimeSegment {
        return RegionalOvertimeSegment(
            code: code,
            label: label,
            description: "",
            checksum: "",
            graceDays: 0,
            durationMinutes: 0,
            cost: 0.0,
            locale: "",
            ceiling: 0.0,
            category: "",
            status: RegionalOvertimeSegmentStatus.created
        )
    }
}
