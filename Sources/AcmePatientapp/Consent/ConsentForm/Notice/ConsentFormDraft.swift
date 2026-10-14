import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form draft is in its life cycle.
    enum ConsentFormDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One consent form draft, with what the planners need to act on it.
    final class ConsentFormDraft {
        var code: String
        var name: String
        var cost: Double
        var floorValue: Double
        var active: Bool
        var channel: String
        var endsAt: Int
        var status: ConsentFormDraftStatus

        init(code: String, name: String, cost: Double, floorValue: Double, active: Bool, channel: String, endsAt: Int, status: ConsentFormDraftStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.floorValue = floorValue
            self.active = active
            self.channel = channel
            self.endsAt = endsAt
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

        func canMoveTo(_ next: ConsentFormDraftStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ConsentFormDraftStatus.rejected || next == ConsentFormDraftStatus.withdrawn
            case .rejected:
                return next == ConsentFormDraftStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return ((Double(endsAt) - cost) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormDraft {
            return ConsentFormDraft(
                code: code,
                name: name,
                cost: cost,
                floorValue: floorValue,
                active: active,
                channel: channel,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a consent form draft in status proposed.
    static func newConsentFormDraft(_ code: String, name: String) -> ConsentFormDraft {
        return ConsentFormDraft(
            code: code,
            name: name,
            cost: 0.0,
            floorValue: 0.0,
            active: false,
            channel: "",
            endsAt: 0,
            status: ConsentFormDraftStatus.proposed
        )
    }
}
