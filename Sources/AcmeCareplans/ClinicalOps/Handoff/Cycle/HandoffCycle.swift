import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff cycle is in its life cycle.
    enum HandoffCycleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A handoff cycle as the handoff team keeps it.
    final class HandoffCycle {
        var code: String
        var name: String
        var specialty: String
        var phone: String
        var amount: Double
        var tags: [String]
        var maximum: Double
        var facility: String
        var status: HandoffCycleStatus

        init(code: String, name: String, specialty: String, phone: String, amount: Double, tags: [String], maximum: Double, facility: String, status: HandoffCycleStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.phone = phone
            self.amount = amount
            self.tags = tags
            self.maximum = maximum
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: HandoffCycleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == HandoffCycleStatus.resolved || next == HandoffCycleStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == HandoffCycleStatus.reopened || next == HandoffCycleStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: HandoffCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedExposure() -> Double {
            return ((maximum + amount) * 100).rounded() / 100
        }

        func copyValue() -> HandoffCycle {
            return HandoffCycle(
                code: code,
                name: name,
                specialty: specialty,
                phone: phone,
                amount: amount,
                tags: tags,
                maximum: maximum,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a handoff cycle in status open.
    static func newHandoffCycle(_ code: String, name: String) -> HandoffCycle {
        return HandoffCycle(
            code: code,
            name: name,
            specialty: "",
            phone: "",
            amount: 0.0,
            tags: [],
            maximum: 0.0,
            facility: "",
            status: HandoffCycleStatus.`open`
        )
    }
}
