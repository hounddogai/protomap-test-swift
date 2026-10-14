import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a seasonal authorization agreement is in its life cycle.
    enum SeasonalAuthorizationAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A seasonal authorization agreement. Its code is unique within a tenant.
    final class SeasonalAuthorizationAgreement {
        var code: String
        var title: String
        var dosageMg: Double
        var source: String
        var encounterID: String
        var weight: Double
        var endsAt: Int
        var floorValue: Double
        var refills: Int
        var country: String
        var retries: Int
        var status: SeasonalAuthorizationAgreementStatus

        init(code: String, title: String, dosageMg: Double, source: String, encounterID: String, weight: Double, endsAt: Int, floorValue: Double, refills: Int, country: String, retries: Int, status: SeasonalAuthorizationAgreementStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.source = source
            self.encounterID = encounterID
            self.weight = weight
            self.endsAt = endsAt
            self.floorValue = floorValue
            self.refills = refills
            self.country = country
            self.retries = retries
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

        func canMoveTo(_ next: SeasonalAuthorizationAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == SeasonalAuthorizationAgreementStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: SeasonalAuthorizationAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal authorization agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedExposure() -> Double {
            return (dosageMg * floorValue * 100).rounded() / 100
        }

        func copyValue() -> SeasonalAuthorizationAgreement {
            return SeasonalAuthorizationAgreement(
                code: code,
                title: title,
                dosageMg: dosageMg,
                source: source,
                encounterID: encounterID,
                weight: weight,
                endsAt: endsAt,
                floorValue: floorValue,
                refills: refills,
                country: country,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a seasonal authorization agreement in status open.
    static func newSeasonalAuthorizationAgreement(_ code: String, title: String) -> SeasonalAuthorizationAgreement {
        return SeasonalAuthorizationAgreement(
            code: code,
            title: title,
            dosageMg: 0.0,
            source: "",
            encounterID: "",
            weight: 0.0,
            endsAt: 0,
            floorValue: 0.0,
            refills: 0,
            country: "",
            retries: 0,
            status: SeasonalAuthorizationAgreementStatus.`open`
        )
    }
}
