import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure threshold is in its life cycle.
    enum DisclosureThresholdStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a disclosure threshold and its current status.
    final class DisclosureThreshold {
        var code: String
        var name: String
        var visitMinutes: Int
        var ratio: Double
        var facility: String
        var archived: Bool
        var status: DisclosureThresholdStatus

        init(code: String, name: String, visitMinutes: Int, ratio: Double, facility: String, archived: Bool, status: DisclosureThresholdStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.ratio = ratio
            self.facility = facility
            self.archived = archived
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

        func canMoveTo(_ next: DisclosureThresholdStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == DisclosureThresholdStatus.draining
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

        func moveTo(_ next: DisclosureThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("disclosure threshold") \(code)"
        }

        func netLoad() -> Double {
            return ((ratio + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureThreshold {
            return DisclosureThreshold(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                ratio: ratio,
                facility: facility,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a disclosure threshold in status idle.
    static func newDisclosureThreshold(_ code: String, name: String) -> DisclosureThreshold {
        return DisclosureThreshold(
            code: code,
            name: name,
            visitMinutes: 0,
            ratio: 0.0,
            facility: "",
            archived: false,
            status: DisclosureThresholdStatus.idle
        )
    }
}
