import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary overtime variance is in its life cycle.
    enum PrimaryOvertimeVarianceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One primary overtime variance, with what the planners need to act on it.
    final class PrimaryOvertimeVariance {
        var code: String
        var label: String
        var attempts: Int
        var timezone: String
        var segment: String
        var copay: Double
        var title: String
        var limit: Int
        var endsAt: Int
        var ownerID: String
        var status: PrimaryOvertimeVarianceStatus

        init(code: String, label: String, attempts: Int, timezone: String, segment: String, copay: Double, title: String, limit: Int, endsAt: Int, ownerID: String, status: PrimaryOvertimeVarianceStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.timezone = timezone
            self.segment = segment
            self.copay = copay
            self.title = title
            self.limit = limit
            self.endsAt = endsAt
            self.ownerID = ownerID
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

        func canMoveTo(_ next: PrimaryOvertimeVarianceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PrimaryOvertimeVarianceStatus.suspended || next == PrimaryOvertimeVarianceStatus.closed
            case .suspended:
                return next == PrimaryOvertimeVarianceStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryOvertimeVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary overtime variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedVolume() -> Double {
            return ((Double(attempts) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryOvertimeVariance {
            return PrimaryOvertimeVariance(
                code: code,
                label: label,
                attempts: attempts,
                timezone: timezone,
                segment: segment,
                copay: copay,
                title: title,
                limit: limit,
                endsAt: endsAt,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a primary overtime variance in status draft.
    static func newPrimaryOvertimeVariance(_ code: String, label: String) -> PrimaryOvertimeVariance {
        return PrimaryOvertimeVariance(
            code: code,
            label: label,
            attempts: 0,
            timezone: "",
            segment: "",
            copay: 0.0,
            title: "",
            limit: 0,
            endsAt: 0,
            ownerID: "",
            status: PrimaryOvertimeVarianceStatus.draft
        )
    }
}
