import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census notice is in its life cycle.
    enum CensusNoticeStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A census notice as the census team keeps it.
    final class CensusNotice {
        var code: String
        var title: String
        var capacity: Int
        var timezone: String
        var amount: Double
        var payer: String
        var quantity: Int
        var source: String
        var approved: Bool
        var durationMinutes: Int
        var reviewer: String
        var status: CensusNoticeStatus

        init(code: String, title: String, capacity: Int, timezone: String, amount: Double, payer: String, quantity: Int, source: String, approved: Bool, durationMinutes: Int, reviewer: String, status: CensusNoticeStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.timezone = timezone
            self.amount = amount
            self.payer = payer
            self.quantity = quantity
            self.source = source
            self.approved = approved
            self.durationMinutes = durationMinutes
            self.reviewer = reviewer
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

        func canMoveTo(_ next: CensusNoticeStatus) -> Bool {
            switch status {
            case .idle:
                return next == CensusNoticeStatus.draining
            case .warming:
                return next == CensusNoticeStatus.draining
            case .ready:
                return next == CensusNoticeStatus.draining
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

        func moveTo(_ next: CensusNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("census notice") \(code)"
        }

        func projectedExposure() -> Double {
            return (Double(quantity) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> CensusNotice {
            return CensusNotice(
                code: code,
                title: title,
                capacity: capacity,
                timezone: timezone,
                amount: amount,
                payer: payer,
                quantity: quantity,
                source: source,
                approved: approved,
                durationMinutes: durationMinutes,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a census notice in status idle.
    static func newCensusNotice(_ code: String, title: String) -> CensusNotice {
        return CensusNotice(
            code: code,
            title: title,
            capacity: 0,
            timezone: "",
            amount: 0.0,
            payer: "",
            quantity: 0,
            source: "",
            approved: false,
            durationMinutes: 0,
            reviewer: "",
            status: CensusNoticeStatus.idle
        )
    }
}
