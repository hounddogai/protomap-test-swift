import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback slot milestone is in its life cycle.
    enum FallbackSlotMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a fallback slot milestone and its current status.
    final class FallbackSlotMilestone {
        var code: String
        var name: String
        var timezone: String
        var cost: Double
        var ceiling: Double
        var country: String
        var startsAt: Int
        var contactEmail: String
        var dosageMg: Double
        var visitMinutes: Int
        var status: FallbackSlotMilestoneStatus

        init(code: String, name: String, timezone: String, cost: Double, ceiling: Double, country: String, startsAt: Int, contactEmail: String, dosageMg: Double, visitMinutes: Int, status: FallbackSlotMilestoneStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.cost = cost
            self.ceiling = ceiling
            self.country = country
            self.startsAt = startsAt
            self.contactEmail = contactEmail
            self.dosageMg = dosageMg
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackSlotMilestoneStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == FallbackSlotMilestoneStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackSlotMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback slot milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netExposure() -> Double {
            return (ceiling * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> FallbackSlotMilestone {
            return FallbackSlotMilestone(
                code: code,
                name: name,
                timezone: timezone,
                cost: cost,
                ceiling: ceiling,
                country: country,
                startsAt: startsAt,
                contactEmail: contactEmail,
                dosageMg: dosageMg,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback slot milestone in status new.
    static func newFallbackSlotMilestone(_ code: String, name: String) -> FallbackSlotMilestone {
        return FallbackSlotMilestone(
            code: code,
            name: name,
            timezone: "",
            cost: 0.0,
            ceiling: 0.0,
            country: "",
            startsAt: 0,
            contactEmail: "",
            dosageMg: 0.0,
            visitMinutes: 0,
            status: FallbackSlotMilestoneStatus.new
        )
    }
}
