import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary risk score profile is in its life cycle.
    enum PrimaryRiskScoreProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One primary risk score profile, with what the planners need to act on it.
    final class PrimaryRiskScoreProfile {
        var code: String
        var title: String
        var quantity: Int
        var attributes: [String: String]
        var bed: String
        var startsAt: Int
        var ownerID: String
        var clinicianID: String
        var weight: Double
        var windowDays: Int
        var status: PrimaryRiskScoreProfileStatus

        init(code: String, title: String, quantity: Int, attributes: [String: String], bed: String, startsAt: Int, ownerID: String, clinicianID: String, weight: Double, windowDays: Int, status: PrimaryRiskScoreProfileStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.attributes = attributes
            self.bed = bed
            self.startsAt = startsAt
            self.ownerID = ownerID
            self.clinicianID = clinicianID
            self.weight = weight
            self.windowDays = windowDays
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

        func canMoveTo(_ next: PrimaryRiskScoreProfileStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PrimaryRiskScoreProfileStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: PrimaryRiskScoreProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary risk score profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary risk score profile") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedVolume() -> Double {
            return ((Double(quantity) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRiskScoreProfile {
            return PrimaryRiskScoreProfile(
                code: code,
                title: title,
                quantity: quantity,
                attributes: attributes,
                bed: bed,
                startsAt: startsAt,
                ownerID: ownerID,
                clinicianID: clinicianID,
                weight: weight,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a primary risk score profile in status idle.
    static func newPrimaryRiskScoreProfile(_ code: String, title: String) -> PrimaryRiskScoreProfile {
        return PrimaryRiskScoreProfile(
            code: code,
            title: title,
            quantity: 0,
            attributes: [:],
            bed: "",
            startsAt: 0,
            ownerID: "",
            clinicianID: "",
            weight: 0.0,
            windowDays: 0,
            status: PrimaryRiskScoreProfileStatus.idle
        )
    }
}
