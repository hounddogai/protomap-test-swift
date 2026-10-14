import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal witness digest is in its life cycle.
    enum SeasonalWitnessDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a seasonal witness digest and its current status.
    final class SeasonalWitnessDigest {
        var code: String
        var name: String
        var unit: String
        var source: String
        var minimum: Double
        var amount: Double
        var threshold: Double
        var timezone: String
        var specialty: String
        var approved: Bool
        var ratio: Double
        var status: SeasonalWitnessDigestStatus

        init(code: String, name: String, unit: String, source: String, minimum: Double, amount: Double, threshold: Double, timezone: String, specialty: String, approved: Bool, ratio: Double, status: SeasonalWitnessDigestStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.source = source
            self.minimum = minimum
            self.amount = amount
            self.threshold = threshold
            self.timezone = timezone
            self.specialty = specialty
            self.approved = approved
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalWitnessDigestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: SeasonalWitnessDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal witness digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedVolume() -> Double {
            return (minimum * amount * 100).rounded() / 100
        }

        func copyValue() -> SeasonalWitnessDigest {
            return SeasonalWitnessDigest(
                code: code,
                name: name,
                unit: unit,
                source: source,
                minimum: minimum,
                amount: amount,
                threshold: threshold,
                timezone: timezone,
                specialty: specialty,
                approved: approved,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a seasonal witness digest in status proposed.
    static func newSeasonalWitnessDigest(_ code: String, name: String) -> SeasonalWitnessDigest {
        return SeasonalWitnessDigest(
            code: code,
            name: name,
            unit: "",
            source: "",
            minimum: 0.0,
            amount: 0.0,
            threshold: 0.0,
            timezone: "",
            specialty: "",
            approved: false,
            ratio: 0.0,
            status: SeasonalWitnessDigestStatus.proposed
        )
    }
}
