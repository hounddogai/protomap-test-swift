import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution group is in its life cycle.
    enum SubstitutionGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A substitution group as the substitution team keeps it.
    final class SubstitutionGroup {
        var code: String
        var name: String
        var limit: Int
        var capacity: Int
        var active: Bool
        var discount: Double
        var externalRef: String
        var startsAt: Int
        var locale: String
        var status: SubstitutionGroupStatus

        init(code: String, name: String, limit: Int, capacity: Int, active: Bool, discount: Double, externalRef: String, startsAt: Int, locale: String, status: SubstitutionGroupStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.capacity = capacity
            self.active = active
            self.discount = discount
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.locale = locale
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

        func canMoveTo(_ next: SubstitutionGroupStatus) -> Bool {
            switch status {
            case .requested:
                return next == SubstitutionGroupStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == SubstitutionGroupStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netTotal() -> Double {
            return (Double(capacity) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionGroup {
            return SubstitutionGroup(
                code: code,
                name: name,
                limit: limit,
                capacity: capacity,
                active: active,
                discount: discount,
                externalRef: externalRef,
                startsAt: startsAt,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a substitution group in status requested.
    static func newSubstitutionGroup(_ code: String, name: String) -> SubstitutionGroup {
        return SubstitutionGroup(
            code: code,
            name: name,
            limit: 0,
            capacity: 0,
            active: false,
            discount: 0.0,
            externalRef: "",
            startsAt: 0,
            locale: "",
            status: SubstitutionGroupStatus.requested
        )
    }
}
