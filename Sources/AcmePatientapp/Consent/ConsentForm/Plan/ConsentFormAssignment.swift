import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form assignment is in its life cycle.
    enum ConsentFormAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One consent form assignment, with what the planners need to act on it.
    final class ConsentFormAssignment {
        var code: String
        var label: String
        var externalRef: String
        var threshold: Double
        var windowDays: Int
        var channel: String
        var durationMinutes: Int
        var weight: Double
        var status: ConsentFormAssignmentStatus

        init(code: String, label: String, externalRef: String, threshold: Double, windowDays: Int, channel: String, durationMinutes: Int, weight: Double, status: ConsentFormAssignmentStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.threshold = threshold
            self.windowDays = windowDays
            self.channel = channel
            self.durationMinutes = durationMinutes
            self.weight = weight
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

        func canMoveTo(_ next: ConsentFormAssignmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ConsentFormAssignmentStatus.published || next == ConsentFormAssignmentStatus.retired
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

        func moveTo(_ next: ConsentFormAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netExposure() -> Double {
            return ((Double(durationMinutes) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormAssignment {
            return ConsentFormAssignment(
                code: code,
                label: label,
                externalRef: externalRef,
                threshold: threshold,
                windowDays: windowDays,
                channel: channel,
                durationMinutes: durationMinutes,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a consent form assignment in status created.
    static func newConsentFormAssignment(_ code: String, label: String) -> ConsentFormAssignment {
        return ConsentFormAssignment(
            code: code,
            label: label,
            externalRef: "",
            threshold: 0.0,
            windowDays: 0,
            channel: "",
            durationMinutes: 0,
            weight: 0.0,
            status: ConsentFormAssignmentStatus.created
        )
    }
}
