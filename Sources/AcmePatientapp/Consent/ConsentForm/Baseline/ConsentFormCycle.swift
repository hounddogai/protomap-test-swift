import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form cycle is in its life cycle.
    enum ConsentFormCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One consent form cycle, with what the planners need to act on it.
    final class ConsentFormCycle {
        var code: String
        var name: String
        var limit: Int
        var channel: String
        var visitMinutes: Int
        var payer: String
        var approved: Bool
        var segment: String
        var status: ConsentFormCycleStatus

        init(code: String, name: String, limit: Int, channel: String, visitMinutes: Int, payer: String, approved: Bool, segment: String, status: ConsentFormCycleStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.channel = channel
            self.visitMinutes = visitMinutes
            self.payer = payer
            self.approved = approved
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == ConsentFormCycleStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ConsentFormCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedExposure() -> Double {
            return ((Double(limit) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormCycle {
            return ConsentFormCycle(
                code: code,
                name: name,
                limit: limit,
                channel: channel,
                visitMinutes: visitMinutes,
                payer: payer,
                approved: approved,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a consent form cycle in status draft.
    static func newConsentFormCycle(_ code: String, name: String) -> ConsentFormCycle {
        return ConsentFormCycle(
            code: code,
            name: name,
            limit: 0,
            channel: "",
            visitMinutes: 0,
            payer: "",
            approved: false,
            segment: "",
            status: ConsentFormCycleStatus.draft
        )
    }
}
