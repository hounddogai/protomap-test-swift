import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory draft is in its life cycle.
    enum InventoryDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A inventory draft as the inventory team keeps it.
    final class InventoryDraft {
        var code: String
        var title: String
        var limit: Int
        var threshold: Double
        var currency: String
        var startsAt: Int
        var facility: String
        var category: String
        var maximum: Double
        var approved: Bool
        var status: InventoryDraftStatus

        init(code: String, title: String, limit: Int, threshold: Double, currency: String, startsAt: Int, facility: String, category: String, maximum: Double, approved: Bool, status: InventoryDraftStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.threshold = threshold
            self.currency = currency
            self.startsAt = startsAt
            self.facility = facility
            self.category = category
            self.maximum = maximum
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

        func canMoveTo(_ next: InventoryDraftStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
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
                return next == InventoryDraftStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InventoryDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedExposure() -> Double {
            return (maximum * threshold * 100).rounded() / 100
        }

        func copyValue() -> InventoryDraft {
            return InventoryDraft(
                code: code,
                title: title,
                limit: limit,
                threshold: threshold,
                currency: currency,
                startsAt: startsAt,
                facility: facility,
                category: category,
                maximum: maximum,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a inventory draft in status open.
    static func newInventoryDraft(_ code: String, title: String) -> InventoryDraft {
        return InventoryDraft(
            code: code,
            title: title,
            limit: 0,
            threshold: 0.0,
            currency: "",
            startsAt: 0,
            facility: "",
            category: "",
            maximum: 0.0,
            approved: false,
            status: InventoryDraftStatus.`open`
        )
    }
}
