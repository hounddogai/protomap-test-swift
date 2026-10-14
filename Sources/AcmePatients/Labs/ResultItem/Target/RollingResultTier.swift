import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling result tier is in its life cycle.
    enum RollingResultTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling result tier as the result team keeps it.
    final class RollingResultTier {
        var code: String
        var title: String
        var description: String
        var sequence: Int
        var facility: String
        var attributes: [String: String]
        var ratio: Double
        var graceDays: Int
        var contactEmail: String
        var country: String
        var capacity: Int
        var status: RollingResultTierStatus

        init(code: String, title: String, description: String, sequence: Int, facility: String, attributes: [String: String], ratio: Double, graceDays: Int, contactEmail: String, country: String, capacity: Int, status: RollingResultTierStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.sequence = sequence
            self.facility = facility
            self.attributes = attributes
            self.ratio = ratio
            self.graceDays = graceDays
            self.contactEmail = contactEmail
            self.country = country
            self.capacity = capacity
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

        func canMoveTo(_ next: RollingResultTierStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RollingResultTierStatus.suspended || next == RollingResultTierStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RollingResultTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling result tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func projectedLoad() -> Double {
            return (Double(capacity) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> RollingResultTier {
            return RollingResultTier(
                code: code,
                title: title,
                description: description,
                sequence: sequence,
                facility: facility,
                attributes: attributes,
                ratio: ratio,
                graceDays: graceDays,
                contactEmail: contactEmail,
                country: country,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a rolling result tier in status draft.
    static func newRollingResultTier(_ code: String, title: String) -> RollingResultTier {
        return RollingResultTier(
            code: code,
            title: title,
            description: "",
            sequence: 0,
            facility: "",
            attributes: [:],
            ratio: 0.0,
            graceDays: 0,
            contactEmail: "",
            country: "",
            capacity: 0,
            status: RollingResultTierStatus.draft
        )
    }
}
