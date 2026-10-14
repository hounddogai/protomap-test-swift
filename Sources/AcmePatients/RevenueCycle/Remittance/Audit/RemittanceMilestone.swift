import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance milestone is in its life cycle.
    enum RemittanceMilestoneStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A remittance milestone as the remittance team keeps it.
    final class RemittanceMilestone {
        var code: String
        var title: String
        var country: String
        var ownerID: String
        var weight: Double
        var graceDays: Int
        var windowDays: Int
        var dosageMg: Double
        var quantity: Int
        var copay: Double
        var status: RemittanceMilestoneStatus

        init(code: String, title: String, country: String, ownerID: String, weight: Double, graceDays: Int, windowDays: Int, dosageMg: Double, quantity: Int, copay: Double, status: RemittanceMilestoneStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.ownerID = ownerID
            self.weight = weight
            self.graceDays = graceDays
            self.windowDays = windowDays
            self.dosageMg = dosageMg
            self.quantity = quantity
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RemittanceMilestoneStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RemittanceMilestoneStatus.completed || next == RemittanceMilestoneStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RemittanceMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("remittance milestone") \(code)"
        }

        func adjustedValue() -> Double {
            return (Double(windowDays) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceMilestone {
            return RemittanceMilestone(
                code: code,
                title: title,
                country: country,
                ownerID: ownerID,
                weight: weight,
                graceDays: graceDays,
                windowDays: windowDays,
                dosageMg: dosageMg,
                quantity: quantity,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a remittance milestone in status planned.
    static func newRemittanceMilestone(_ code: String, title: String) -> RemittanceMilestone {
        return RemittanceMilestone(
            code: code,
            title: title,
            country: "",
            ownerID: "",
            weight: 0.0,
            graceDays: 0,
            windowDays: 0,
            dosageMg: 0.0,
            quantity: 0,
            copay: 0.0,
            status: RemittanceMilestoneStatus.planned
        )
    }
}
