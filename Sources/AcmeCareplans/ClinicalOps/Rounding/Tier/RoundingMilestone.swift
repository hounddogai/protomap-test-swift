import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding milestone is in its life cycle.
    enum RoundingMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One rounding milestone, with what the planners need to act on it.
    final class RoundingMilestone {
        var code: String
        var name: String
        var rate: Double
        var label: String
        var limit: Int
        var locale: String
        var notes: String
        var contactEmail: String
        var status: RoundingMilestoneStatus

        init(code: String, name: String, rate: Double, label: String, limit: Int, locale: String, notes: String, contactEmail: String, status: RoundingMilestoneStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.label = label
            self.limit = limit
            self.locale = locale
            self.notes = notes
            self.contactEmail = contactEmail
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RoundingMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RoundingMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RoundingMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func adjustedExposure() -> Double {
            return ((rate - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingMilestone {
            return RoundingMilestone(
                code: code,
                name: name,
                rate: rate,
                label: label,
                limit: limit,
                locale: locale,
                notes: notes,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a rounding milestone in status idle.
    static func newRoundingMilestone(_ code: String, name: String) -> RoundingMilestone {
        return RoundingMilestone(
            code: code,
            name: name,
            rate: 0.0,
            label: "",
            limit: 0,
            locale: "",
            notes: "",
            contactEmail: "",
            status: RoundingMilestoneStatus.idle
        )
    }
}
