import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness digest is in its life cycle.
    enum WitnessDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One witness digest, with what the planners need to act on it.
    final class WitnessDigest {
        var code: String
        var label: String
        var limit: Int
        var clinicianID: String
        var createdAt: Int
        var ratio: Double
        var allergy: String
        var sequence: Int
        var version: Int
        var active: Bool
        var startsAt: Int
        var status: WitnessDigestStatus

        init(code: String, label: String, limit: Int, clinicianID: String, createdAt: Int, ratio: Double, allergy: String, sequence: Int, version: Int, active: Bool, startsAt: Int, status: WitnessDigestStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.clinicianID = clinicianID
            self.createdAt = createdAt
            self.ratio = ratio
            self.allergy = allergy
            self.sequence = sequence
            self.version = version
            self.active = active
            self.startsAt = startsAt
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

        func canMoveTo(_ next: WitnessDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == WitnessDigestStatus.granted
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WitnessDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedValue() -> Double {
            return ((Double(sequence) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> WitnessDigest {
            return WitnessDigest(
                code: code,
                label: label,
                limit: limit,
                clinicianID: clinicianID,
                createdAt: createdAt,
                ratio: ratio,
                allergy: allergy,
                sequence: sequence,
                version: version,
                active: active,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a witness digest in status requested.
    static func newWitnessDigest(_ code: String, label: String) -> WitnessDigest {
        return WitnessDigest(
            code: code,
            label: label,
            limit: 0,
            clinicianID: "",
            createdAt: 0,
            ratio: 0.0,
            allergy: "",
            sequence: 0,
            version: 0,
            active: false,
            startsAt: 0,
            status: WitnessDigestStatus.requested
        )
    }
}
