import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol budget is in its life cycle.
    enum CareProtocolBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One care protocol budget, with what the planners need to act on it.
    final class CareProtocolBudget {
        var code: String
        var name: String
        var limit: Int
        var attributes: [String: String]
        var notes: String
        var status: CareProtocolBudgetStatus

        init(code: String, name: String, limit: Int, attributes: [String: String], notes: String, status: CareProtocolBudgetStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.attributes = attributes
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolBudgetStatus) -> Bool {
            switch status {
            case .requested:
                return next == CareProtocolBudgetStatus.granted
            case .granted:
                return next == CareProtocolBudgetStatus.revoked || next == CareProtocolBudgetStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CareProtocolBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol budget") \(code)"
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

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> CareProtocolBudget {
            return CareProtocolBudget(
                code: code,
                name: name,
                limit: limit,
                attributes: attributes,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol budget in status requested.
    static func newCareProtocolBudget(_ code: String, name: String) -> CareProtocolBudget {
        return CareProtocolBudget(
            code: code,
            name: name,
            limit: 0,
            attributes: [:],
            notes: "",
            status: CareProtocolBudgetStatus.requested
        )
    }
}
