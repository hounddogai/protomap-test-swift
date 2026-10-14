import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall claim is in its life cycle.
    enum RecallClaimStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a recall claim and its current status.
    final class RecallClaim {
        var code: String
        var name: String
        var segment: String
        var encounterID: String
        var floorValue: Double
        var status: RecallClaimStatus

        init(code: String, name: String, segment: String, encounterID: String, floorValue: Double, status: RecallClaimStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.encounterID = encounterID
            self.floorValue = floorValue
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

        func canMoveTo(_ next: RecallClaimStatus) -> Bool {
            switch status {
            case .idle:
                return next == RecallClaimStatus.stopped
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RecallClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("recall claim") \(code)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> RecallClaim {
            return RecallClaim(
                code: code,
                name: name,
                segment: segment,
                encounterID: encounterID,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a recall claim in status idle.
    static func newRecallClaim(_ code: String, name: String) -> RecallClaim {
        return RecallClaim(
            code: code,
            name: name,
            segment: "",
            encounterID: "",
            floorValue: 0.0,
            status: RecallClaimStatus.idle
        )
    }
}
