import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal referral mapping is in its life cycle.
    enum SeasonalReferralMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a seasonal referral mapping and its current status.
    final class SeasonalReferralMapping {
        var code: String
        var label: String
        var source: String
        var priority: Int
        var clinicianID: String
        var status: SeasonalReferralMappingStatus

        init(code: String, label: String, source: String, priority: Int, clinicianID: String, status: SeasonalReferralMappingStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.priority = priority
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: SeasonalReferralMappingStatus) -> Bool {
            switch status {
            case .draft:
                return next == SeasonalReferralMappingStatus.suspended || next == SeasonalReferralMappingStatus.closed
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SeasonalReferralMappingStatus.closed
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

        func moveTo(_ next: SeasonalReferralMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal referral mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal referral mapping") \(code)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> SeasonalReferralMapping {
            return SeasonalReferralMapping(
                code: code,
                label: label,
                source: source,
                priority: priority,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a seasonal referral mapping in status draft.
    static func newSeasonalReferralMapping(_ code: String, label: String) -> SeasonalReferralMapping {
        return SeasonalReferralMapping(
            code: code,
            label: label,
            source: "",
            priority: 0,
            clinicianID: "",
            status: SeasonalReferralMappingStatus.draft
        )
    }
}
