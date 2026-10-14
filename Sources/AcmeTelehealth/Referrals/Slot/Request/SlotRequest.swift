import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot request is in its life cycle.
    enum SlotRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A slot request. Its code is unique within a tenant.
    final class SlotRequest {
        var code: String
        var name: String
        var budget: Double
        var country: String
        var approved: Bool
        var summary: String
        var retries: Int
        var weight: Double
        var margin: Double
        var status: SlotRequestStatus

        init(code: String, name: String, budget: Double, country: String, approved: Bool, summary: String, retries: Int, weight: Double, margin: Double, status: SlotRequestStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.country = country
            self.approved = approved
            self.summary = summary
            self.retries = retries
            self.weight = weight
            self.margin = margin
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

        func canMoveTo(_ next: SlotRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SlotRequestStatus.suspended || next == SlotRequestStatus.closed
            case .suspended:
                return next == SlotRequestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return (budget * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> SlotRequest {
            return SlotRequest(
                code: code,
                name: name,
                budget: budget,
                country: country,
                approved: approved,
                summary: summary,
                retries: retries,
                weight: weight,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a slot request in status draft.
    static func newSlotRequest(_ code: String, name: String) -> SlotRequest {
        return SlotRequest(
            code: code,
            name: name,
            budget: 0.0,
            country: "",
            approved: false,
            summary: "",
            retries: 0,
            weight: 0.0,
            margin: 0.0,
            status: SlotRequestStatus.draft
        )
    }
}
