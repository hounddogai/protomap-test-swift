import AcmePlatform
import Foundation

extension Consent {
    /// Where a adaptive witness group is in its life cycle.
    enum AdaptiveWitnessGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive witness group. Its code is unique within a tenant.
    final class AdaptiveWitnessGroup {
        var code: String
        var title: String
        var specialty: String
        var channel: String
        var ratio: Double
        var allergy: String
        var priority: Int
        var externalRef: String
        var limit: Int
        var status: AdaptiveWitnessGroupStatus

        init(code: String, title: String, specialty: String, channel: String, ratio: Double, allergy: String, priority: Int, externalRef: String, limit: Int, status: AdaptiveWitnessGroupStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.channel = channel
            self.ratio = ratio
            self.allergy = allergy
            self.priority = priority
            self.externalRef = externalRef
            self.limit = limit
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

        func canMoveTo(_ next: AdaptiveWitnessGroupStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptiveWitnessGroupStatus.granted || next == AdaptiveWitnessGroupStatus.expired
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == AdaptiveWitnessGroupStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveWitnessGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive witness group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return (ratio * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveWitnessGroup {
            return AdaptiveWitnessGroup(
                code: code,
                title: title,
                specialty: specialty,
                channel: channel,
                ratio: ratio,
                allergy: allergy,
                priority: priority,
                externalRef: externalRef,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a adaptive witness group in status requested.
    static func newAdaptiveWitnessGroup(_ code: String, title: String) -> AdaptiveWitnessGroup {
        return AdaptiveWitnessGroup(
            code: code,
            title: title,
            specialty: "",
            channel: "",
            ratio: 0.0,
            allergy: "",
            priority: 0,
            externalRef: "",
            limit: 0,
            status: AdaptiveWitnessGroupStatus.requested
        )
    }
}
