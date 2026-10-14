import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive assessment allocation is in its life cycle.
    enum AdaptiveAssessmentAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One adaptive assessment allocation, with what the planners need to act on it.
    final class AdaptiveAssessmentAllocation {
        var code: String
        var name: String
        var channel: String
        var threshold: Double
        var externalRef: String
        var windowDays: Int
        var specialty: String
        var maximum: Double
        var status: AdaptiveAssessmentAllocationStatus

        init(code: String, name: String, channel: String, threshold: Double, externalRef: String, windowDays: Int, specialty: String, maximum: Double, status: AdaptiveAssessmentAllocationStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.threshold = threshold
            self.externalRef = externalRef
            self.windowDays = windowDays
            self.specialty = specialty
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveAssessmentAllocationStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptiveAssessmentAllocationStatus.granted
            case .granted:
                return next == AdaptiveAssessmentAllocationStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AdaptiveAssessmentAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive assessment allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive assessment allocation") \(code)"
        }

        func netVolume() -> Double {
            return ((maximum - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveAssessmentAllocation {
            return AdaptiveAssessmentAllocation(
                code: code,
                name: name,
                channel: channel,
                threshold: threshold,
                externalRef: externalRef,
                windowDays: windowDays,
                specialty: specialty,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a adaptive assessment allocation in status requested.
    static func newAdaptiveAssessmentAllocation(_ code: String, name: String) -> AdaptiveAssessmentAllocation {
        return AdaptiveAssessmentAllocation(
            code: code,
            name: name,
            channel: "",
            threshold: 0.0,
            externalRef: "",
            windowDays: 0,
            specialty: "",
            maximum: 0.0,
            status: AdaptiveAssessmentAllocationStatus.requested
        )
    }
}
