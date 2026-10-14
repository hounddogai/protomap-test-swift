import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall threshold is in its life cycle.
    enum RecallThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a recall threshold and its current status.
    final class RecallThreshold {
        var code: String
        var name: String
        var facility: String
        var maximum: Double
        var ratio: Double
        var encounterID: String
        var endsAt: Int
        var status: RecallThresholdStatus

        init(code: String, name: String, facility: String, maximum: Double, ratio: Double, encounterID: String, endsAt: Int, status: RecallThresholdStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.maximum = maximum
            self.ratio = ratio
            self.encounterID = encounterID
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

        func canMoveTo(_ next: RecallThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RecallThresholdStatus.rejected || next == RecallThresholdStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RecallThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(endsAt) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> RecallThreshold {
            return RecallThreshold(
                code: code,
                name: name,
                facility: facility,
                maximum: maximum,
                ratio: ratio,
                encounterID: encounterID,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a recall threshold in status proposed.
    static func newRecallThreshold(_ code: String, name: String) -> RecallThreshold {
        return RecallThreshold(
            code: code,
            name: name,
            facility: "",
            maximum: 0.0,
            ratio: 0.0,
            encounterID: "",
            endsAt: 0,
            status: RecallThresholdStatus.proposed
        )
    }
}
