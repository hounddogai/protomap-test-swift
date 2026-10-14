import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional recall request is in its life cycle.
    enum RegionalRecallRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A regional recall request. Its code is unique within a tenant.
    final class RegionalRecallRequest {
        var code: String
        var title: String
        var ward: String
        var active: Bool
        var unit: String
        var visitMinutes: Int
        var attempts: Int
        var status: RegionalRecallRequestStatus

        init(code: String, title: String, ward: String, active: Bool, unit: String, visitMinutes: Int, attempts: Int, status: RegionalRecallRequestStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.active = active
            self.unit = unit
            self.visitMinutes = visitMinutes
            self.attempts = attempts
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

        func canMoveTo(_ next: RegionalRecallRequestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RegionalRecallRequestStatus.reopened
            case .resolved:
                return next == RegionalRecallRequestStatus.reopened || next == RegionalRecallRequestStatus.archived
            case .reopened:
                return next == RegionalRecallRequestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalRecallRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional recall request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return ((Double(attempts) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalRecallRequest {
            return RegionalRecallRequest(
                code: code,
                title: title,
                ward: ward,
                active: active,
                unit: unit,
                visitMinutes: visitMinutes,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a regional recall request in status open.
    static func newRegionalRecallRequest(_ code: String, title: String) -> RegionalRecallRequest {
        return RegionalRecallRequest(
            code: code,
            title: title,
            ward: "",
            active: false,
            unit: "",
            visitMinutes: 0,
            attempts: 0,
            status: RegionalRecallRequestStatus.`open`
        )
    }
}
