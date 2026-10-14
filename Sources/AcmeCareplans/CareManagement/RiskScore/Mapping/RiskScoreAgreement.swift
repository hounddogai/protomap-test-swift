import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score agreement is in its life cycle.
    enum RiskScoreAgreementStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a risk score agreement and its current status.
    final class RiskScoreAgreement {
        var code: String
        var name: String
        var country: String
        var startsAt: Int
        var timezone: String
        var copay: Double
        var region: String
        var batchSize: Int
        var attributes: [String: String]
        var threshold: Double
        var ownerID: String
        var status: RiskScoreAgreementStatus

        init(code: String, name: String, country: String, startsAt: Int, timezone: String, copay: Double, region: String, batchSize: Int, attributes: [String: String], threshold: Double, ownerID: String, status: RiskScoreAgreementStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.startsAt = startsAt
            self.timezone = timezone
            self.copay = copay
            self.region = region
            self.batchSize = batchSize
            self.attributes = attributes
            self.threshold = threshold
            self.ownerID = ownerID
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

        func canMoveTo(_ next: RiskScoreAgreementStatus) -> Bool {
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

        func moveTo(_ next: RiskScoreAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("risk score agreement") \(code)"
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

        func effectiveVolume() -> Double {
            return ((Double(batchSize) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreAgreement {
            return RiskScoreAgreement(
                code: code,
                name: name,
                country: country,
                startsAt: startsAt,
                timezone: timezone,
                copay: copay,
                region: region,
                batchSize: batchSize,
                attributes: attributes,
                threshold: threshold,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a risk score agreement in status requested.
    static func newRiskScoreAgreement(_ code: String, name: String) -> RiskScoreAgreement {
        return RiskScoreAgreement(
            code: code,
            name: name,
            country: "",
            startsAt: 0,
            timezone: "",
            copay: 0.0,
            region: "",
            batchSize: 0,
            attributes: [:],
            threshold: 0.0,
            ownerID: "",
            status: RiskScoreAgreementStatus.requested
        )
    }
}
