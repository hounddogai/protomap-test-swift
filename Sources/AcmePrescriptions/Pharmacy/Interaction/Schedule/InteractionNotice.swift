import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction notice is in its life cycle.
    enum InteractionNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One interaction notice, with what the planners need to act on it.
    final class InteractionNotice {
        var code: String
        var label: String
        var rate: Double
        var createdAt: Int
        var weight: Double
        var endsAt: Int
        var timezone: String
        var facility: String
        var tags: [String]
        var status: InteractionNoticeStatus

        init(code: String, label: String, rate: Double, createdAt: Int, weight: Double, endsAt: Int, timezone: String, facility: String, tags: [String], status: InteractionNoticeStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.createdAt = createdAt
            self.weight = weight
            self.endsAt = endsAt
            self.timezone = timezone
            self.facility = facility
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

        func canMoveTo(_ next: InteractionNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                return next == InteractionNoticeStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
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

        func moveTo(_ next: InteractionNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("interaction notice") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedValue() -> Double {
            return (weight * rate * 100).rounded() / 100
        }

        func copyValue() -> InteractionNotice {
            return InteractionNotice(
                code: code,
                label: label,
                rate: rate,
                createdAt: createdAt,
                weight: weight,
                endsAt: endsAt,
                timezone: timezone,
                facility: facility,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a interaction notice in status proposed.
    static func newInteractionNotice(_ code: String, label: String) -> InteractionNotice {
        return InteractionNotice(
            code: code,
            label: label,
            rate: 0.0,
            createdAt: 0,
            weight: 0.0,
            endsAt: 0,
            timezone: "",
            facility: "",
            tags: [],
            status: InteractionNoticeStatus.proposed
        )
    }
}
