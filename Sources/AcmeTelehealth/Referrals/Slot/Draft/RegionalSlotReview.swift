import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional slot review is in its life cycle.
    enum RegionalSlotReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A regional slot review as the slot team keeps it.
    final class RegionalSlotReview {
        var code: String
        var title: String
        var encounterID: String
        var attempts: Int
        var allergy: String
        var procedureCode: String
        var status: RegionalSlotReviewStatus

        init(code: String, title: String, encounterID: String, attempts: Int, allergy: String, procedureCode: String, status: RegionalSlotReviewStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.attempts = attempts
            self.allergy = allergy
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalSlotReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == RegionalSlotReviewStatus.ready || next == RegionalSlotReviewStatus.draining
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == RegionalSlotReviewStatus.draining
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RegionalSlotReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional slot review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional slot review") \(code)"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> RegionalSlotReview {
            return RegionalSlotReview(
                code: code,
                title: title,
                encounterID: encounterID,
                attempts: attempts,
                allergy: allergy,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional slot review in status idle.
    static func newRegionalSlotReview(_ code: String, title: String) -> RegionalSlotReview {
        return RegionalSlotReview(
            code: code,
            title: title,
            encounterID: "",
            attempts: 0,
            allergy: "",
            procedureCode: "",
            status: RegionalSlotReviewStatus.idle
        )
    }
}
