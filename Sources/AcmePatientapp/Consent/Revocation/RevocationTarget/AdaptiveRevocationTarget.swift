import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive revocation target is in its life cycle.
    enum AdaptiveRevocationTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a adaptive revocation target and its current status.
    final class AdaptiveRevocationTarget {
        var code: String
        var title: String
        var floorValue: Double
        var contactEmail: String
        var sequence: Int
        var segment: String
        var status: AdaptiveRevocationTargetStatus

        init(code: String, title: String, floorValue: Double, contactEmail: String, sequence: Int, segment: String, status: AdaptiveRevocationTargetStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.contactEmail = contactEmail
            self.sequence = sequence
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveRevocationTargetStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveRevocationTargetStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: AdaptiveRevocationTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive revocation target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveLoad() -> Double {
            return (Double(sequence) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRevocationTarget {
            return AdaptiveRevocationTarget(
                code: code,
                title: title,
                floorValue: floorValue,
                contactEmail: contactEmail,
                sequence: sequence,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a adaptive revocation target in status created.
    static func newAdaptiveRevocationTarget(_ code: String, title: String) -> AdaptiveRevocationTarget {
        return AdaptiveRevocationTarget(
            code: code,
            title: title,
            floorValue: 0.0,
            contactEmail: "",
            sequence: 0,
            segment: "",
            status: AdaptiveRevocationTargetStatus.created
        )
    }
}
