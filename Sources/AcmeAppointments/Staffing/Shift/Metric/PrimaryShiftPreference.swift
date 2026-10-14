import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary shift preference is in its life cycle.
    enum PrimaryShiftPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a primary shift preference and its current status.
    final class PrimaryShiftPreference {
        var code: String
        var title: String
        var channel: String
        var quantity: Int
        var score: Double
        var startsAt: Int
        var active: Bool
        var revision: Int
        var description: String
        var status: PrimaryShiftPreferenceStatus

        init(code: String, title: String, channel: String, quantity: Int, score: Double, startsAt: Int, active: Bool, revision: Int, description: String, status: PrimaryShiftPreferenceStatus) {
            self.code = code
            self.title = title
            self.channel = channel
            self.quantity = quantity
            self.score = score
            self.startsAt = startsAt
            self.active = active
            self.revision = revision
            self.description = description
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

        func canMoveTo(_ next: PrimaryShiftPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PrimaryShiftPreferenceStatus.rejected || next == PrimaryShiftPreferenceStatus.withdrawn
            case .rejected:
                return next == PrimaryShiftPreferenceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryShiftPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary shift preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("primary shift preference") \(code)"
        }

        func weightedTotal() -> Double {
            return (score * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryShiftPreference {
            return PrimaryShiftPreference(
                code: code,
                title: title,
                channel: channel,
                quantity: quantity,
                score: score,
                startsAt: startsAt,
                active: active,
                revision: revision,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary shift preference in status proposed.
    static func newPrimaryShiftPreference(_ code: String, title: String) -> PrimaryShiftPreference {
        return PrimaryShiftPreference(
            code: code,
            title: title,
            channel: "",
            quantity: 0,
            score: 0.0,
            startsAt: 0,
            active: false,
            revision: 0,
            description: "",
            status: PrimaryShiftPreferenceStatus.proposed
        )
    }
}
