import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier claim is in its life cycle.
    enum CourierClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a courier claim and its current status.
    final class CourierClaim {
        var code: String
        var name: String
        var contactEmail: String
        var updatedAt: Int
        var visitMinutes: Int
        var summary: String
        var windowDays: Int
        var tags: [String]
        var status: CourierClaimStatus

        init(code: String, name: String, contactEmail: String, updatedAt: Int, visitMinutes: Int, summary: String, windowDays: Int, tags: [String], status: CourierClaimStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.updatedAt = updatedAt
            self.visitMinutes = visitMinutes
            self.summary = summary
            self.windowDays = windowDays
            self.tags = tags
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

        func canMoveTo(_ next: CourierClaimStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CourierClaimStatus.approved || next == CourierClaimStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CourierClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("courier claim") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedTotal() -> Double {
            return ((Double(windowDays) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CourierClaim {
            return CourierClaim(
                code: code,
                name: name,
                contactEmail: contactEmail,
                updatedAt: updatedAt,
                visitMinutes: visitMinutes,
                summary: summary,
                windowDays: windowDays,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a courier claim in status proposed.
    static func newCourierClaim(_ code: String, name: String) -> CourierClaim {
        return CourierClaim(
            code: code,
            name: name,
            contactEmail: "",
            updatedAt: 0,
            visitMinutes: 0,
            summary: "",
            windowDays: 0,
            tags: [],
            status: CourierClaimStatus.proposed
        )
    }
}
