import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict order set tier is in its life cycle.
    enum StrictOrderSetTierStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a strict order set tier and its current status.
    final class StrictOrderSetTier {
        var code: String
        var title: String
        var encounterID: String
        var checksum: String
        var discount: Double
        var attempts: Int
        var phone: String
        var status: StrictOrderSetTierStatus

        init(code: String, title: String, encounterID: String, checksum: String, discount: Double, attempts: Int, phone: String, status: StrictOrderSetTierStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.checksum = checksum
            self.discount = discount
            self.attempts = attempts
            self.phone = phone
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

        func canMoveTo(_ next: StrictOrderSetTierStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == StrictOrderSetTierStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictOrderSetTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict order set tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return ((Double(attempts) + discount) * 100).rounded() / 100
        }

        func copyValue() -> StrictOrderSetTier {
            return StrictOrderSetTier(
                code: code,
                title: title,
                encounterID: encounterID,
                checksum: checksum,
                discount: discount,
                attempts: attempts,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict order set tier in status open.
    static func newStrictOrderSetTier(_ code: String, title: String) -> StrictOrderSetTier {
        return StrictOrderSetTier(
            code: code,
            title: title,
            encounterID: "",
            checksum: "",
            discount: 0.0,
            attempts: 0,
            phone: "",
            status: StrictOrderSetTierStatus.`open`
        )
    }
}
