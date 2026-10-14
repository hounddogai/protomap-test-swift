import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped closure notice is in its life cycle.
    enum CappedClosureNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One capped closure notice, with what the planners need to act on it.
    final class CappedClosureNotice {
        var code: String
        var name: String
        var endsAt: Int
        var rate: Double
        var visible: Bool
        var facility: String
        var status: CappedClosureNoticeStatus

        init(code: String, name: String, endsAt: Int, rate: Double, visible: Bool, facility: String, status: CappedClosureNoticeStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.rate = rate
            self.visible = visible
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedClosureNoticeStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CappedClosureNoticeStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CappedClosureNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped closure notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedVolume() -> Double {
            return (rate * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedClosureNotice {
            return CappedClosureNotice(
                code: code,
                name: name,
                endsAt: endsAt,
                rate: rate,
                visible: visible,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a capped closure notice in status created.
    static func newCappedClosureNotice(_ code: String, name: String) -> CappedClosureNotice {
        return CappedClosureNotice(
            code: code,
            name: name,
            endsAt: 0,
            rate: 0.0,
            visible: false,
            facility: "",
            status: CappedClosureNoticeStatus.created
        )
    }
}
