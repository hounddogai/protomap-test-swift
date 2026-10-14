import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol allocation is in its life cycle.
    enum CareProtocolAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a care protocol allocation and its current status.
    final class CareProtocolAllocation {
        var code: String
        var name: String
        var attempts: Int
        var facility: String
        var acuity: Int
        var channel: String
        var title: String
        var rate: Double
        var status: CareProtocolAllocationStatus

        init(code: String, name: String, attempts: Int, facility: String, acuity: Int, channel: String, title: String, rate: Double, status: CareProtocolAllocationStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.facility = facility
            self.acuity = acuity
            self.channel = channel
            self.title = title
            self.rate = rate
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

        func canMoveTo(_ next: CareProtocolAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CareProtocolAllocationStatus.resolved || next == CareProtocolAllocationStatus.archived
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CareProtocolAllocationStatus.reopened || next == CareProtocolAllocationStatus.archived
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

        func moveTo(_ next: CareProtocolAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol allocation") \(code)"
        }

        func weightedVolume() -> Double {
            return (rate * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolAllocation {
            return CareProtocolAllocation(
                code: code,
                name: name,
                attempts: attempts,
                facility: facility,
                acuity: acuity,
                channel: channel,
                title: title,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a care protocol allocation in status open.
    static func newCareProtocolAllocation(_ code: String, name: String) -> CareProtocolAllocation {
        return CareProtocolAllocation(
            code: code,
            name: name,
            attempts: 0,
            facility: "",
            acuity: 0,
            channel: "",
            title: "",
            rate: 0.0,
            status: CareProtocolAllocationStatus.`open`
        )
    }
}
