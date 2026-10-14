import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal modality audit is in its life cycle.
    enum SeasonalModalityAuditStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A seasonal modality audit as the modality team keeps it.
    final class SeasonalModalityAudit {
        var code: String
        var title: String
        var clinicianID: String
        var allergy: String
        var maximum: Double
        var startsAt: Int
        var reviewer: String
        var attempts: Int
        var facility: String
        var amount: Double
        var floorValue: Double
        var status: SeasonalModalityAuditStatus

        init(code: String, title: String, clinicianID: String, allergy: String, maximum: Double, startsAt: Int, reviewer: String, attempts: Int, facility: String, amount: Double, floorValue: Double, status: SeasonalModalityAuditStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.allergy = allergy
            self.maximum = maximum
            self.startsAt = startsAt
            self.reviewer = reviewer
            self.attempts = attempts
            self.facility = facility
            self.amount = amount
            self.floorValue = floorValue
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

        func canMoveTo(_ next: SeasonalModalityAuditStatus) -> Bool {
            switch status {
            case .draft:
                return next == SeasonalModalityAuditStatus.active || next == SeasonalModalityAuditStatus.suspended
            case .pending:
                return next == SeasonalModalityAuditStatus.active || next == SeasonalModalityAuditStatus.closed
            case .active:
                return next == SeasonalModalityAuditStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: SeasonalModalityAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal modality audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal modality audit") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((maximum - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalModalityAudit {
            return SeasonalModalityAudit(
                code: code,
                title: title,
                clinicianID: clinicianID,
                allergy: allergy,
                maximum: maximum,
                startsAt: startsAt,
                reviewer: reviewer,
                attempts: attempts,
                facility: facility,
                amount: amount,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a seasonal modality audit in status draft.
    static func newSeasonalModalityAudit(_ code: String, title: String) -> SeasonalModalityAudit {
        return SeasonalModalityAudit(
            code: code,
            title: title,
            clinicianID: "",
            allergy: "",
            maximum: 0.0,
            startsAt: 0,
            reviewer: "",
            attempts: 0,
            facility: "",
            amount: 0.0,
            floorValue: 0.0,
            status: SeasonalModalityAuditStatus.draft
        )
    }
}
