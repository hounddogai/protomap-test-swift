import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure manifest is in its life cycle.
    enum ClosureManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a closure manifest and its current status.
    final class ClosureManifest {
        var code: String
        var title: String
        var visible: Bool
        var clinicianID: String
        var batchSize: Int
        var ward: String
        var dosageMg: Double
        var specialty: String
        var score: Double
        var status: ClosureManifestStatus

        init(code: String, title: String, visible: Bool, clinicianID: String, batchSize: Int, ward: String, dosageMg: Double, specialty: String, score: Double, status: ClosureManifestStatus) {
            self.code = code
            self.title = title
            self.visible = visible
            self.clinicianID = clinicianID
            self.batchSize = batchSize
            self.ward = ward
            self.dosageMg = dosageMg
            self.specialty = specialty
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

        func canMoveTo(_ next: ClosureManifestStatus) -> Bool {
            switch status {
            case .requested:
                return next == ClosureManifestStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ClosureManifestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveLoad() -> Double {
            return (score * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> ClosureManifest {
            return ClosureManifest(
                code: code,
                title: title,
                visible: visible,
                clinicianID: clinicianID,
                batchSize: batchSize,
                ward: ward,
                dosageMg: dosageMg,
                specialty: specialty,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a closure manifest in status requested.
    static func newClosureManifest(_ code: String, title: String) -> ClosureManifest {
        return ClosureManifest(
            code: code,
            title: title,
            visible: false,
            clinicianID: "",
            batchSize: 0,
            ward: "",
            dosageMg: 0.0,
            specialty: "",
            score: 0.0,
            status: ClosureManifestStatus.requested
        )
    }
}
