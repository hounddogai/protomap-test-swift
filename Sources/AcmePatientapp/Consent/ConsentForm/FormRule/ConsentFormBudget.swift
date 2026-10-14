import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form budget is in its life cycle.
    enum ConsentFormBudgetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a consent form budget and its current status.
    final class ConsentFormBudget {
        var code: String
        var name: String
        var pinned: Bool
        var margin: Double
        var segment: String
        var durationMinutes: Int
        var revision: Int
        var encounterID: String
        var endsAt: Int
        var channel: String
        var status: ConsentFormBudgetStatus

        init(code: String, name: String, pinned: Bool, margin: Double, segment: String, durationMinutes: Int, revision: Int, encounterID: String, endsAt: Int, channel: String, status: ConsentFormBudgetStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.margin = margin
            self.segment = segment
            self.durationMinutes = durationMinutes
            self.revision = revision
            self.encounterID = encounterID
            self.endsAt = endsAt
            self.channel = channel
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

        func canMoveTo(_ next: ConsentFormBudgetStatus) -> Bool {
            switch status {
            case .idle:
                return next == ConsentFormBudgetStatus.stopped
            case .warming:
                return next == ConsentFormBudgetStatus.ready
            case .ready:
                return next == ConsentFormBudgetStatus.stopped
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

        func moveTo(_ next: ConsentFormBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return (margin * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormBudget {
            return ConsentFormBudget(
                code: code,
                name: name,
                pinned: pinned,
                margin: margin,
                segment: segment,
                durationMinutes: durationMinutes,
                revision: revision,
                encounterID: encounterID,
                endsAt: endsAt,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a consent form budget in status idle.
    static func newConsentFormBudget(_ code: String, name: String) -> ConsentFormBudget {
        return ConsentFormBudget(
            code: code,
            name: name,
            pinned: false,
            margin: 0.0,
            segment: "",
            durationMinutes: 0,
            revision: 0,
            encounterID: "",
            endsAt: 0,
            channel: "",
            status: ConsentFormBudgetStatus.idle
        )
    }
}
