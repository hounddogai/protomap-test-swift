import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel policy is in its life cycle.
    enum PanelPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a panel policy and its current status.
    final class PanelPolicy {
        var code: String
        var title: String
        var windowDays: Int
        var contactEmail: String
        var floorValue: Double
        var bed: String
        var batchSize: Int
        var status: PanelPolicyStatus

        init(code: String, title: String, windowDays: Int, contactEmail: String, floorValue: Double, bed: String, batchSize: Int, status: PanelPolicyStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.contactEmail = contactEmail
            self.floorValue = floorValue
            self.bed = bed
            self.batchSize = batchSize
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

        func canMoveTo(_ next: PanelPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PanelPolicyStatus.withdrawn
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

        func moveTo(_ next: PanelPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("panel policy") \(code)"
        }

        func netTotal() -> Double {
            return (Double(windowDays) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> PanelPolicy {
            return PanelPolicy(
                code: code,
                title: title,
                windowDays: windowDays,
                contactEmail: contactEmail,
                floorValue: floorValue,
                bed: bed,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a panel policy in status proposed.
    static func newPanelPolicy(_ code: String, title: String) -> PanelPolicy {
        return PanelPolicy(
            code: code,
            title: title,
            windowDays: 0,
            contactEmail: "",
            floorValue: 0.0,
            bed: "",
            batchSize: 0,
            status: PanelPolicyStatus.proposed
        )
    }
}
