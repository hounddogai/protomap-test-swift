import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered rounding request is in its life cycle.
    enum TieredRoundingRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One tiered rounding request, with what the planners need to act on it.
    final class TieredRoundingRequest {
        var code: String
        var title: String
        var attributes: [String: String]
        var timezone: String
        var amount: Double
        var attempts: Int
        var copay: Double
        var allergy: String
        var ownerID: String
        var approved: Bool
        var status: TieredRoundingRequestStatus

        init(code: String, title: String, attributes: [String: String], timezone: String, amount: Double, attempts: Int, copay: Double, allergy: String, ownerID: String, approved: Bool, status: TieredRoundingRequestStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.timezone = timezone
            self.amount = amount
            self.attempts = attempts
            self.copay = copay
            self.allergy = allergy
            self.ownerID = ownerID
            self.approved = approved
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

        func canMoveTo(_ next: TieredRoundingRequestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TieredRoundingRequestStatus.inReview
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == TieredRoundingRequestStatus.reopened
            case .reopened:
                return next == TieredRoundingRequestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRoundingRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered rounding request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedVolume() -> Double {
            return ((Double(attempts) - amount) * 100).rounded() / 100
        }

        func copyValue() -> TieredRoundingRequest {
            return TieredRoundingRequest(
                code: code,
                title: title,
                attributes: attributes,
                timezone: timezone,
                amount: amount,
                attempts: attempts,
                copay: copay,
                allergy: allergy,
                ownerID: ownerID,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered rounding request in status open.
    static func newTieredRoundingRequest(_ code: String, title: String) -> TieredRoundingRequest {
        return TieredRoundingRequest(
            code: code,
            title: title,
            attributes: [:],
            timezone: "",
            amount: 0.0,
            attempts: 0,
            copay: 0.0,
            allergy: "",
            ownerID: "",
            approved: false,
            status: TieredRoundingRequestStatus.`open`
        )
    }
}
