import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered follow up baseline is in its life cycle.
    enum TieredFollowUpBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a tiered follow up baseline and its current status.
    final class TieredFollowUpBaseline {
        var code: String
        var title: String
        var country: String
        var limit: Int
        var batchSize: Int
        var approved: Bool
        var minimum: Double
        var specialty: String
        var ownerID: String
        var status: TieredFollowUpBaselineStatus

        init(code: String, title: String, country: String, limit: Int, batchSize: Int, approved: Bool, minimum: Double, specialty: String, ownerID: String, status: TieredFollowUpBaselineStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.limit = limit
            self.batchSize = batchSize
            self.approved = approved
            self.minimum = minimum
            self.specialty = specialty
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredFollowUpBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: TieredFollowUpBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered follow up baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedTotal() -> Double {
            return ((Double(limit) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> TieredFollowUpBaseline {
            return TieredFollowUpBaseline(
                code: code,
                title: title,
                country: country,
                limit: limit,
                batchSize: batchSize,
                approved: approved,
                minimum: minimum,
                specialty: specialty,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered follow up baseline in status proposed.
    static func newTieredFollowUpBaseline(_ code: String, title: String) -> TieredFollowUpBaseline {
        return TieredFollowUpBaseline(
            code: code,
            title: title,
            country: "",
            limit: 0,
            batchSize: 0,
            approved: false,
            minimum: 0.0,
            specialty: "",
            ownerID: "",
            status: TieredFollowUpBaselineStatus.proposed
        )
    }
}
