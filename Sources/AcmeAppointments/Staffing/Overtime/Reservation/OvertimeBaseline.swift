import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime baseline is in its life cycle.
    enum OvertimeBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A overtime baseline. Its code is unique within a tenant.
    final class OvertimeBaseline {
        var code: String
        var title: String
        var ward: String
        var summary: String
        var maximum: Double
        var reviewer: String
        var budget: Double
        var status: OvertimeBaselineStatus

        init(code: String, title: String, ward: String, summary: String, maximum: Double, reviewer: String, budget: Double, status: OvertimeBaselineStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.summary = summary
            self.maximum = maximum
            self.reviewer = reviewer
            self.budget = budget
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

        func canMoveTo(_ next: OvertimeBaselineStatus) -> Bool {
            switch status {
            case .requested:
                return next == OvertimeBaselineStatus.granted || next == OvertimeBaselineStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == OvertimeBaselineStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("overtime baseline") \(code)"
        }

        func adjustedValue() -> Double {
            return ((maximum - budget) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeBaseline {
            return OvertimeBaseline(
                code: code,
                title: title,
                ward: ward,
                summary: summary,
                maximum: maximum,
                reviewer: reviewer,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a overtime baseline in status requested.
    static func newOvertimeBaseline(_ code: String, title: String) -> OvertimeBaseline {
        return OvertimeBaseline(
            code: code,
            title: title,
            ward: "",
            summary: "",
            maximum: 0.0,
            reviewer: "",
            budget: 0.0,
            status: OvertimeBaselineStatus.requested
        )
    }
}
