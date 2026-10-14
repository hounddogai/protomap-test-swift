import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy result request is in its life cycle.
    enum LegacyResultRequestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a legacy result request and its current status.
    final class LegacyResultRequest {
        var code: String
        var title: String
        var durationMinutes: Int
        var expiresAt: Int
        var allergy: String
        var ceiling: Double
        var cost: Double
        var active: Bool
        var endsAt: Int
        var status: LegacyResultRequestStatus

        init(code: String, title: String, durationMinutes: Int, expiresAt: Int, allergy: String, ceiling: Double, cost: Double, active: Bool, endsAt: Int, status: LegacyResultRequestStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.allergy = allergy
            self.ceiling = ceiling
            self.cost = cost
            self.active = active
            self.endsAt = endsAt
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

        func canMoveTo(_ next: LegacyResultRequestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: LegacyResultRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy result request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveTotal() -> Double {
            return (Double(expiresAt) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> LegacyResultRequest {
            return LegacyResultRequest(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                allergy: allergy,
                ceiling: ceiling,
                cost: cost,
                active: active,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy result request in status planned.
    static func newLegacyResultRequest(_ code: String, title: String) -> LegacyResultRequest {
        return LegacyResultRequest(
            code: code,
            title: title,
            durationMinutes: 0,
            expiresAt: 0,
            allergy: "",
            ceiling: 0.0,
            cost: 0.0,
            active: false,
            endsAt: 0,
            status: LegacyResultRequestStatus.planned
        )
    }
}
