import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network override is in its life cycle.
    enum NetworkOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One network override, with what the planners need to act on it.
    final class NetworkOverride {
        var code: String
        var name: String
        var allergy: String
        var patientRef: String
        var locale: String
        var refills: Int
        var startsAt: Int
        var status: NetworkOverrideStatus

        init(code: String, name: String, allergy: String, patientRef: String, locale: String, refills: Int, startsAt: Int, status: NetworkOverrideStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.patientRef = patientRef
            self.locale = locale
            self.refills = refills
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                return next == NetworkOverrideStatus.resolved || next == NetworkOverrideStatus.archived
            case .inReview:
                return next == NetworkOverrideStatus.resolved || next == NetworkOverrideStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == NetworkOverrideStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("network override") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(startsAt) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkOverride {
            return NetworkOverride(
                code: code,
                name: name,
                allergy: allergy,
                patientRef: patientRef,
                locale: locale,
                refills: refills,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a network override in status open.
    static func newNetworkOverride(_ code: String, name: String) -> NetworkOverride {
        return NetworkOverride(
            code: code,
            name: name,
            allergy: "",
            patientRef: "",
            locale: "",
            refills: 0,
            startsAt: 0,
            status: NetworkOverrideStatus.`open`
        )
    }
}
