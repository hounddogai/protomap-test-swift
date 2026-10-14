import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted language digest is in its life cycle.
    enum WeightedLanguageDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted language digest as the language team keeps it.
    final class WeightedLanguageDigest {
        var code: String
        var name: String
        var allergy: String
        var facility: String
        var payer: String
        var batchSize: Int
        var procedureCode: String
        var encounterID: String
        var refills: Int
        var timezone: String
        var ratio: Double
        var status: WeightedLanguageDigestStatus

        init(code: String, name: String, allergy: String, facility: String, payer: String, batchSize: Int, procedureCode: String, encounterID: String, refills: Int, timezone: String, ratio: Double, status: WeightedLanguageDigestStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.facility = facility
            self.payer = payer
            self.batchSize = batchSize
            self.procedureCode = procedureCode
            self.encounterID = encounterID
            self.refills = refills
            self.timezone = timezone
            self.ratio = ratio
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

        func canMoveTo(_ next: WeightedLanguageDigestStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == WeightedLanguageDigestStatus.revoked
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

        func moveTo(_ next: WeightedLanguageDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted language digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveVolume() -> Double {
            return ((ratio + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedLanguageDigest {
            return WeightedLanguageDigest(
                code: code,
                name: name,
                allergy: allergy,
                facility: facility,
                payer: payer,
                batchSize: batchSize,
                procedureCode: procedureCode,
                encounterID: encounterID,
                refills: refills,
                timezone: timezone,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted language digest in status requested.
    static func newWeightedLanguageDigest(_ code: String, name: String) -> WeightedLanguageDigest {
        return WeightedLanguageDigest(
            code: code,
            name: name,
            allergy: "",
            facility: "",
            payer: "",
            batchSize: 0,
            procedureCode: "",
            encounterID: "",
            refills: 0,
            timezone: "",
            ratio: 0.0,
            status: WeightedLanguageDigestStatus.requested
        )
    }
}
