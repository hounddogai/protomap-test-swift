import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime override is in its life cycle.
    enum OvertimeOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A overtime override. Its code is unique within a tenant.
    final class OvertimeOverride {
        var code: String
        var name: String
        var notes: String
        var channel: String
        var payer: String
        var endsAt: Int
        var locale: String
        var createdAt: Int
        var status: OvertimeOverrideStatus

        init(code: String, name: String, notes: String, channel: String, payer: String, endsAt: Int, locale: String, createdAt: Int, status: OvertimeOverrideStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.channel = channel
            self.payer = payer
            self.endsAt = endsAt
            self.locale = locale
            self.createdAt = createdAt
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

        func canMoveTo(_ next: OvertimeOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == OvertimeOverrideStatus.reopened || next == OvertimeOverrideStatus.archived
            case .reopened:
                return next == OvertimeOverrideStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netVolume() -> Double {
            return ((Double(endsAt) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeOverride {
            return OvertimeOverride(
                code: code,
                name: name,
                notes: notes,
                channel: channel,
                payer: payer,
                endsAt: endsAt,
                locale: locale,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a overtime override in status open.
    static func newOvertimeOverride(_ code: String, name: String) -> OvertimeOverride {
        return OvertimeOverride(
            code: code,
            name: name,
            notes: "",
            channel: "",
            payer: "",
            endsAt: 0,
            locale: "",
            createdAt: 0,
            status: OvertimeOverrideStatus.`open`
        )
    }
}
