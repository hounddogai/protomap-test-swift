import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual formulary allocation is in its life cycle.
    enum ManualFormularyAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a manual formulary allocation and its current status.
    final class ManualFormularyAllocation {
        var code: String
        var title: String
        var endsAt: Int
        var facility: String
        var ratio: Double
        var description: String
        var status: ManualFormularyAllocationStatus

        init(code: String, title: String, endsAt: Int, facility: String, ratio: Double, description: String, status: ManualFormularyAllocationStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.facility = facility
            self.ratio = ratio
            self.description = description
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

        func canMoveTo(_ next: ManualFormularyAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ManualFormularyAllocationStatus.resolved
            case .resolved:
                return next == ManualFormularyAllocationStatus.reopened || next == ManualFormularyAllocationStatus.archived
            case .reopened:
                return next == ManualFormularyAllocationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualFormularyAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual formulary allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("manual formulary allocation") \(code)"
        }

        func netValue() -> Double {
            return ((ratio - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ManualFormularyAllocation {
            return ManualFormularyAllocation(
                code: code,
                title: title,
                endsAt: endsAt,
                facility: facility,
                ratio: ratio,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a manual formulary allocation in status open.
    static func newManualFormularyAllocation(_ code: String, title: String) -> ManualFormularyAllocation {
        return ManualFormularyAllocation(
            code: code,
            title: title,
            endsAt: 0,
            facility: "",
            ratio: 0.0,
            description: "",
            status: ManualFormularyAllocationStatus.`open`
        )
    }
}
