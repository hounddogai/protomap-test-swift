import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot tier is in its life cycle.
    enum SlotTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a slot tier and its current status.
    final class SlotTier {
        var code: String
        var title: String
        var name: String
        var diagnosisCode: String
        var threshold: Double
        var status: SlotTierStatus

        init(code: String, title: String, name: String, diagnosisCode: String, threshold: Double, status: SlotTierStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SlotTierStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: SlotTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("slot tier") \(code)"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> SlotTier {
            return SlotTier(
                code: code,
                title: title,
                name: name,
                diagnosisCode: diagnosisCode,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a slot tier in status planned.
    static func newSlotTier(_ code: String, title: String) -> SlotTier {
        return SlotTier(
            code: code,
            title: title,
            name: "",
            diagnosisCode: "",
            threshold: 0.0,
            status: SlotTierStatus.planned
        )
    }
}
