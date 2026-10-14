import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary census notice is in its life cycle.
    enum PrimaryCensusNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A primary census notice as the census team keeps it.
    final class PrimaryCensusNotice {
        var code: String
        var label: String
        var visitMinutes: Int
        var copay: Double
        var ownerID: String
        var reviewer: String
        var active: Bool
        var description: String
        var status: PrimaryCensusNoticeStatus

        init(code: String, label: String, visitMinutes: Int, copay: Double, ownerID: String, reviewer: String, active: Bool, description: String, status: PrimaryCensusNoticeStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.ownerID = ownerID
            self.reviewer = reviewer
            self.active = active
            self.description = description
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

        func canMoveTo(_ next: PrimaryCensusNoticeStatus) -> Bool {
            switch status {
            case .idle:
                return next == PrimaryCensusNoticeStatus.stopped
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

        func moveTo(_ next: PrimaryCensusNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary census notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("primary census notice") \(code)"
        }

        func adjustedValue() -> Double {
            return (copay * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCensusNotice {
            return PrimaryCensusNotice(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                copay: copay,
                ownerID: ownerID,
                reviewer: reviewer,
                active: active,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary census notice in status idle.
    static func newPrimaryCensusNotice(_ code: String, label: String) -> PrimaryCensusNotice {
        return PrimaryCensusNotice(
            code: code,
            label: label,
            visitMinutes: 0,
            copay: 0.0,
            ownerID: "",
            reviewer: "",
            active: false,
            description: "",
            status: PrimaryCensusNoticeStatus.idle
        )
    }
}
