import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim metric is in its life cycle.
    enum ClaimMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A claim metric as the claim team keeps it.
    final class ClaimMetric {
        var code: String
        var name: String
        var windowDays: Int
        var copay: Double
        var tags: [String]
        var contactEmail: String
        var acuity: Int
        var specialty: String
        var status: ClaimMetricStatus

        init(code: String, name: String, windowDays: Int, copay: Double, tags: [String], contactEmail: String, acuity: Int, specialty: String, status: ClaimMetricStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.copay = copay
            self.tags = tags
            self.contactEmail = contactEmail
            self.acuity = acuity
            self.specialty = specialty
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

        func canMoveTo(_ next: ClaimMetricStatus) -> Bool {
            switch status {
            case .requested:
                return next == ClaimMetricStatus.granted || next == ClaimMetricStatus.revoked
            case .granted:
                return next == ClaimMetricStatus.revoked || next == ClaimMetricStatus.expired
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

        func moveTo(_ next: ClaimMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return ((copay - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimMetric {
            return ClaimMetric(
                code: code,
                name: name,
                windowDays: windowDays,
                copay: copay,
                tags: tags,
                contactEmail: contactEmail,
                acuity: acuity,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a claim metric in status requested.
    static func newClaimMetric(_ code: String, name: String) -> ClaimMetric {
        return ClaimMetric(
            code: code,
            name: name,
            windowDays: 0,
            copay: 0.0,
            tags: [],
            contactEmail: "",
            acuity: 0,
            specialty: "",
            status: ClaimMetricStatus.requested
        )
    }
}
