import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal program group is in its life cycle.
    enum SeasonalProgramGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a seasonal program group and its current status.
    final class SeasonalProgramGroup {
        var code: String
        var name: String
        var archived: Bool
        var amount: Double
        var phone: String
        var graceDays: Int
        var threshold: Double
        var expiresAt: Int
        var label: String
        var status: SeasonalProgramGroupStatus

        init(code: String, name: String, archived: Bool, amount: Double, phone: String, graceDays: Int, threshold: Double, expiresAt: Int, label: String, status: SeasonalProgramGroupStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.amount = amount
            self.phone = phone
            self.graceDays = graceDays
            self.threshold = threshold
            self.expiresAt = expiresAt
            self.label = label
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

        func canMoveTo(_ next: SeasonalProgramGroupStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == SeasonalProgramGroupStatus.cancelled
            case .completed:
                return next == SeasonalProgramGroupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalProgramGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal program group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("seasonal program group") \(code)"
        }

        func netExposure() -> Double {
            return ((amount - threshold) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalProgramGroup {
            return SeasonalProgramGroup(
                code: code,
                name: name,
                archived: archived,
                amount: amount,
                phone: phone,
                graceDays: graceDays,
                threshold: threshold,
                expiresAt: expiresAt,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal program group in status planned.
    static func newSeasonalProgramGroup(_ code: String, name: String) -> SeasonalProgramGroup {
        return SeasonalProgramGroup(
            code: code,
            name: name,
            archived: false,
            amount: 0.0,
            phone: "",
            graceDays: 0,
            threshold: 0.0,
            expiresAt: 0,
            label: "",
            status: SeasonalProgramGroupStatus.planned
        )
    }
}
