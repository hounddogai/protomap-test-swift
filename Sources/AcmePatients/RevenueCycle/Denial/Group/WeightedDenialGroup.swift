import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted denial group is in its life cycle.
    enum WeightedDenialGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a weighted denial group and its current status.
    final class WeightedDenialGroup {
        var code: String
        var name: String
        var facility: String
        var ownerID: String
        var maximum: Double
        var allergy: String
        var payer: String
        var status: WeightedDenialGroupStatus

        init(code: String, name: String, facility: String, ownerID: String, maximum: Double, allergy: String, payer: String, status: WeightedDenialGroupStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.ownerID = ownerID
            self.maximum = maximum
            self.allergy = allergy
            self.payer = payer
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

        func canMoveTo(_ next: WeightedDenialGroupStatus) -> Bool {
            switch status {
            case .idle:
                return next == WeightedDenialGroupStatus.ready || next == WeightedDenialGroupStatus.stopped
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: WeightedDenialGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted denial group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> WeightedDenialGroup {
            return WeightedDenialGroup(
                code: code,
                name: name,
                facility: facility,
                ownerID: ownerID,
                maximum: maximum,
                allergy: allergy,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted denial group in status idle.
    static func newWeightedDenialGroup(_ code: String, name: String) -> WeightedDenialGroup {
        return WeightedDenialGroup(
            code: code,
            name: name,
            facility: "",
            ownerID: "",
            maximum: 0.0,
            allergy: "",
            payer: "",
            status: WeightedDenialGroupStatus.idle
        )
    }
}
