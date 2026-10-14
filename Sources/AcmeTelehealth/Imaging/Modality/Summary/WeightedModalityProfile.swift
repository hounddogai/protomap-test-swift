import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted modality profile is in its life cycle.
    enum WeightedModalityProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a weighted modality profile and its current status.
    final class WeightedModalityProfile {
        var code: String
        var name: String
        var pinned: Bool
        var limit: Int
        var clinicianID: String
        var allergy: String
        var minimum: Double
        var budget: Double
        var expiresAt: Int
        var approved: Bool
        var copay: Double
        var status: WeightedModalityProfileStatus

        init(code: String, name: String, pinned: Bool, limit: Int, clinicianID: String, allergy: String, minimum: Double, budget: Double, expiresAt: Int, approved: Bool, copay: Double, status: WeightedModalityProfileStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.limit = limit
            self.clinicianID = clinicianID
            self.allergy = allergy
            self.minimum = minimum
            self.budget = budget
            self.expiresAt = expiresAt
            self.approved = approved
            self.copay = copay
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

        func canMoveTo(_ next: WeightedModalityProfileStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedModalityProfileStatus.granted || next == WeightedModalityProfileStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == WeightedModalityProfileStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedModalityProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted modality profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return ((budget + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedModalityProfile {
            return WeightedModalityProfile(
                code: code,
                name: name,
                pinned: pinned,
                limit: limit,
                clinicianID: clinicianID,
                allergy: allergy,
                minimum: minimum,
                budget: budget,
                expiresAt: expiresAt,
                approved: approved,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted modality profile in status requested.
    static func newWeightedModalityProfile(_ code: String, name: String) -> WeightedModalityProfile {
        return WeightedModalityProfile(
            code: code,
            name: name,
            pinned: false,
            limit: 0,
            clinicianID: "",
            allergy: "",
            minimum: 0.0,
            budget: 0.0,
            expiresAt: 0,
            approved: false,
            copay: 0.0,
            status: WeightedModalityProfileStatus.requested
        )
    }
}
