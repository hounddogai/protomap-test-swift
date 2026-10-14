import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol manifest is in its life cycle.
    enum CareProtocolManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a care protocol manifest and its current status.
    final class CareProtocolManifest {
        var code: String
        var name: String
        var endsAt: Int
        var acuity: Int
        var clinicianID: String
        var allergy: String
        var refills: Int
        var maximum: Double
        var source: String
        var status: CareProtocolManifestStatus

        init(code: String, name: String, endsAt: Int, acuity: Int, clinicianID: String, allergy: String, refills: Int, maximum: Double, source: String, status: CareProtocolManifestStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.acuity = acuity
            self.clinicianID = clinicianID
            self.allergy = allergy
            self.refills = refills
            self.maximum = maximum
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == CareProtocolManifestStatus.validated || next == CareProtocolManifestStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CareProtocolManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedVolume() -> Double {
            return ((Double(endsAt) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolManifest {
            return CareProtocolManifest(
                code: code,
                name: name,
                endsAt: endsAt,
                acuity: acuity,
                clinicianID: clinicianID,
                allergy: allergy,
                refills: refills,
                maximum: maximum,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a care protocol manifest in status created.
    static func newCareProtocolManifest(_ code: String, name: String) -> CareProtocolManifest {
        return CareProtocolManifest(
            code: code,
            name: name,
            endsAt: 0,
            acuity: 0,
            clinicianID: "",
            allergy: "",
            refills: 0,
            maximum: 0.0,
            source: "",
            status: CareProtocolManifestStatus.created
        )
    }
}
