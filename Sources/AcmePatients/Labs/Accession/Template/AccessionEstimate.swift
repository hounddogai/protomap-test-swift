import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession estimate is in its life cycle.
    enum AccessionEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One accession estimate, with what the planners need to act on it.
    final class AccessionEstimate {
        var code: String
        var label: String
        var ceiling: Double
        var refills: Int
        var priority: Int
        var expiresAt: Int
        var phone: String
        var status: AccessionEstimateStatus

        init(code: String, label: String, ceiling: Double, refills: Int, priority: Int, expiresAt: Int, phone: String, status: AccessionEstimateStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.refills = refills
            self.priority = priority
            self.expiresAt = expiresAt
            self.phone = phone
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

        func canMoveTo(_ next: AccessionEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AccessionEstimateStatus.rejected || next == AccessionEstimateStatus.withdrawn
            case .rejected:
                return next == AccessionEstimateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netVolume() -> Double {
            return ((Double(expiresAt) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionEstimate {
            return AccessionEstimate(
                code: code,
                label: label,
                ceiling: ceiling,
                refills: refills,
                priority: priority,
                expiresAt: expiresAt,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a accession estimate in status proposed.
    static func newAccessionEstimate(_ code: String, label: String) -> AccessionEstimate {
        return AccessionEstimate(
            code: code,
            label: label,
            ceiling: 0.0,
            refills: 0,
            priority: 0,
            expiresAt: 0,
            phone: "",
            status: AccessionEstimateStatus.proposed
        )
    }
}
