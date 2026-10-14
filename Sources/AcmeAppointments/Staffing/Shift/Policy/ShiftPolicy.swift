import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift policy is in its life cycle.
    enum ShiftPolicyStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One shift policy, with what the planners need to act on it.
    final class ShiftPolicy {
        var code: String
        var label: String
        var startsAt: Int
        var acuity: Int
        var encounterID: String
        var durationMinutes: Int
        var amount: Double
        var rate: Double
        var notes: String
        var score: Double
        var ratio: Double
        var status: ShiftPolicyStatus

        init(code: String, label: String, startsAt: Int, acuity: Int, encounterID: String, durationMinutes: Int, amount: Double, rate: Double, notes: String, score: Double, ratio: Double, status: ShiftPolicyStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.acuity = acuity
            self.encounterID = encounterID
            self.durationMinutes = durationMinutes
            self.amount = amount
            self.rate = rate
            self.notes = notes
            self.score = score
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftPolicyStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ShiftPolicyStatus.running || next == ShiftPolicyStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ShiftPolicyStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedVolume() -> Double {
            return ((ratio - rate) * 100).rounded() / 100
        }

        func copyValue() -> ShiftPolicy {
            return ShiftPolicy(
                code: code,
                label: label,
                startsAt: startsAt,
                acuity: acuity,
                encounterID: encounterID,
                durationMinutes: durationMinutes,
                amount: amount,
                rate: rate,
                notes: notes,
                score: score,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a shift policy in status new.
    static func newShiftPolicy(_ code: String, label: String) -> ShiftPolicy {
        return ShiftPolicy(
            code: code,
            label: label,
            startsAt: 0,
            acuity: 0,
            encounterID: "",
            durationMinutes: 0,
            amount: 0.0,
            rate: 0.0,
            notes: "",
            score: 0.0,
            ratio: 0.0,
            status: ShiftPolicyStatus.new
        )
    }
}
