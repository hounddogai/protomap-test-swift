import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority milestone is in its life cycle.
    enum PriorityMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A priority milestone. Its code is unique within a tenant.
    final class PriorityMilestone {
        var code: String
        var name: String
        var startsAt: Int
        var rate: Double
        var locale: String
        var unit: String
        var externalRef: String
        var archived: Bool
        var updatedAt: Int
        var clinicianID: String
        var status: PriorityMilestoneStatus

        init(code: String, name: String, startsAt: Int, rate: Double, locale: String, unit: String, externalRef: String, archived: Bool, updatedAt: Int, clinicianID: String, status: PriorityMilestoneStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.rate = rate
            self.locale = locale
            self.unit = unit
            self.externalRef = externalRef
            self.archived = archived
            self.updatedAt = updatedAt
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: PriorityMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == PriorityMilestoneStatus.warming || next == PriorityMilestoneStatus.ready
            case .warming:
                return next == PriorityMilestoneStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PriorityMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netExposure() -> Double {
            return (Double(updatedAt) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> PriorityMilestone {
            return PriorityMilestone(
                code: code,
                name: name,
                startsAt: startsAt,
                rate: rate,
                locale: locale,
                unit: unit,
                externalRef: externalRef,
                archived: archived,
                updatedAt: updatedAt,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a priority milestone in status idle.
    static func newPriorityMilestone(_ code: String, name: String) -> PriorityMilestone {
        return PriorityMilestone(
            code: code,
            name: name,
            startsAt: 0,
            rate: 0.0,
            locale: "",
            unit: "",
            externalRef: "",
            archived: false,
            updatedAt: 0,
            clinicianID: "",
            status: PriorityMilestoneStatus.idle
        )
    }
}
