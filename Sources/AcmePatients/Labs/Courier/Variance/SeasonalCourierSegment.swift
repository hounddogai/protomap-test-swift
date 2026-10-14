import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal courier segment is in its life cycle.
    enum SeasonalCourierSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A seasonal courier segment as the courier team keeps it.
    final class SeasonalCourierSegment {
        var code: String
        var name: String
        var maximum: Double
        var discount: Double
        var facility: String
        var ownerID: String
        var title: String
        var country: String
        var attempts: Int
        var status: SeasonalCourierSegmentStatus

        init(code: String, name: String, maximum: Double, discount: Double, facility: String, ownerID: String, title: String, country: String, attempts: Int, status: SeasonalCourierSegmentStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.discount = discount
            self.facility = facility
            self.ownerID = ownerID
            self.title = title
            self.country = country
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalCourierSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SeasonalCourierSegmentStatus.rejected || next == SeasonalCourierSegmentStatus.withdrawn
            case .approved:
                return next == SeasonalCourierSegmentStatus.rejected || next == SeasonalCourierSegmentStatus.withdrawn
            case .rejected:
                return next == SeasonalCourierSegmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalCourierSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal courier segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal courier segment") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((Double(attempts) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCourierSegment {
            return SeasonalCourierSegment(
                code: code,
                name: name,
                maximum: maximum,
                discount: discount,
                facility: facility,
                ownerID: ownerID,
                title: title,
                country: country,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a seasonal courier segment in status proposed.
    static func newSeasonalCourierSegment(_ code: String, name: String) -> SeasonalCourierSegment {
        return SeasonalCourierSegment(
            code: code,
            name: name,
            maximum: 0.0,
            discount: 0.0,
            facility: "",
            ownerID: "",
            title: "",
            country: "",
            attempts: 0,
            status: SeasonalCourierSegmentStatus.proposed
        )
    }
}
