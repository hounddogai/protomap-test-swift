import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall quota is in its life cycle.
    enum RecallQuotaStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One recall quota, with what the planners need to act on it.
    final class RecallQuota {
        var code: String
        var title: String
        var pinned: Bool
        var graceDays: Int
        var category: String
        var country: String
        var minimum: Double
        var patientRef: String
        var status: RecallQuotaStatus

        init(code: String, title: String, pinned: Bool, graceDays: Int, category: String, country: String, minimum: Double, patientRef: String, status: RecallQuotaStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.graceDays = graceDays
            self.category = category
            self.country = country
            self.minimum = minimum
            self.patientRef = patientRef
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

        func canMoveTo(_ next: RecallQuotaStatus) -> Bool {
            switch status {
            case .planned:
                return next == RecallQuotaStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RecallQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netExposure() -> Double {
            return ((Double(graceDays) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> RecallQuota {
            return RecallQuota(
                code: code,
                title: title,
                pinned: pinned,
                graceDays: graceDays,
                category: category,
                country: country,
                minimum: minimum,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a recall quota in status planned.
    static func newRecallQuota(_ code: String, title: String) -> RecallQuota {
        return RecallQuota(
            code: code,
            title: title,
            pinned: false,
            graceDays: 0,
            category: "",
            country: "",
            minimum: 0.0,
            patientRef: "",
            status: RecallQuotaStatus.planned
        )
    }
}
