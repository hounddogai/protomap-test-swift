import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped formulary milestone is in its life cycle.
    enum CappedFormularyMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A capped formulary milestone as the formulary team keeps it.
    final class CappedFormularyMilestone {
        var code: String
        var title: String
        var dosageMg: Double
        var capacity: Int
        var endsAt: Int
        var refills: Int
        var threshold: Double
        var budget: Double
        var ratio: Double
        var status: CappedFormularyMilestoneStatus

        init(code: String, title: String, dosageMg: Double, capacity: Int, endsAt: Int, refills: Int, threshold: Double, budget: Double, ratio: Double, status: CappedFormularyMilestoneStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.endsAt = endsAt
            self.refills = refills
            self.threshold = threshold
            self.budget = budget
            self.ratio = ratio
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

        func canMoveTo(_ next: CappedFormularyMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: CappedFormularyMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped formulary milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netVolume() -> Double {
            return (budget * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedFormularyMilestone {
            return CappedFormularyMilestone(
                code: code,
                title: title,
                dosageMg: dosageMg,
                capacity: capacity,
                endsAt: endsAt,
                refills: refills,
                threshold: threshold,
                budget: budget,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped formulary milestone in status proposed.
    static func newCappedFormularyMilestone(_ code: String, title: String) -> CappedFormularyMilestone {
        return CappedFormularyMilestone(
            code: code,
            title: title,
            dosageMg: 0.0,
            capacity: 0,
            endsAt: 0,
            refills: 0,
            threshold: 0.0,
            budget: 0.0,
            ratio: 0.0,
            status: CappedFormularyMilestoneStatus.proposed
        )
    }
}
