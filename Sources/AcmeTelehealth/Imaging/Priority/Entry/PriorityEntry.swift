import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority entry is in its life cycle.
    enum PriorityEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A priority entry. Its code is unique within a tenant.
    final class PriorityEntry {
        var code: String
        var name: String
        var createdAt: Int
        var durationMinutes: Int
        var country: String
        var acuity: Int
        var payer: String
        var windowDays: Int
        var ownerID: String
        var category: String
        var status: PriorityEntryStatus

        init(code: String, name: String, createdAt: Int, durationMinutes: Int, country: String, acuity: Int, payer: String, windowDays: Int, ownerID: String, category: String, status: PriorityEntryStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.durationMinutes = durationMinutes
            self.country = country
            self.acuity = acuity
            self.payer = payer
            self.windowDays = windowDays
            self.ownerID = ownerID
            self.category = category
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

        func canMoveTo(_ next: PriorityEntryStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == PriorityEntryStatus.revoked || next == PriorityEntryStatus.expired
            case .revoked:
                return next == PriorityEntryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("priority entry") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(windowDays) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> PriorityEntry {
            return PriorityEntry(
                code: code,
                name: name,
                createdAt: createdAt,
                durationMinutes: durationMinutes,
                country: country,
                acuity: acuity,
                payer: payer,
                windowDays: windowDays,
                ownerID: ownerID,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a priority entry in status requested.
    static func newPriorityEntry(_ code: String, name: String) -> PriorityEntry {
        return PriorityEntry(
            code: code,
            name: name,
            createdAt: 0,
            durationMinutes: 0,
            country: "",
            acuity: 0,
            payer: "",
            windowDays: 0,
            ownerID: "",
            category: "",
            status: PriorityEntryStatus.requested
        )
    }
}
