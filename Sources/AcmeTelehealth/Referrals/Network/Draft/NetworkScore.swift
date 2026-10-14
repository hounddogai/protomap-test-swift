import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network score is in its life cycle.
    enum NetworkScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One network score, with what the planners need to act on it.
    final class NetworkScore {
        var code: String
        var title: String
        var sequence: Int
        var limit: Int
        var cost: Double
        var notes: String
        var encounterID: String
        var acuity: Int
        var allergy: String
        var facility: String
        var score: Double
        var status: NetworkScoreStatus

        init(code: String, title: String, sequence: Int, limit: Int, cost: Double, notes: String, encounterID: String, acuity: Int, allergy: String, facility: String, score: Double, status: NetworkScoreStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.limit = limit
            self.cost = cost
            self.notes = notes
            self.encounterID = encounterID
            self.acuity = acuity
            self.allergy = allergy
            self.facility = facility
            self.score = score
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

        func canMoveTo(_ next: NetworkScoreStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == NetworkScoreStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netExposure() -> Double {
            return ((cost + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkScore {
            return NetworkScore(
                code: code,
                title: title,
                sequence: sequence,
                limit: limit,
                cost: cost,
                notes: notes,
                encounterID: encounterID,
                acuity: acuity,
                allergy: allergy,
                facility: facility,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a network score in status requested.
    static func newNetworkScore(_ code: String, title: String) -> NetworkScore {
        return NetworkScore(
            code: code,
            title: title,
            sequence: 0,
            limit: 0,
            cost: 0.0,
            notes: "",
            encounterID: "",
            acuity: 0,
            allergy: "",
            facility: "",
            score: 0.0,
            status: NetworkScoreStatus.requested
        )
    }
}
