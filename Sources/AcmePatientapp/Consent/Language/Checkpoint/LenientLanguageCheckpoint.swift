import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient language checkpoint is in its life cycle.
    enum LenientLanguageCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient language checkpoint as the language team keeps it.
    final class LenientLanguageCheckpoint {
        var code: String
        var title: String
        var checksum: String
        var description: String
        var refills: Int
        var clinicianID: String
        var ratio: Double
        var status: LenientLanguageCheckpointStatus

        init(code: String, title: String, checksum: String, description: String, refills: Int, clinicianID: String, ratio: Double, status: LenientLanguageCheckpointStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.description = description
            self.refills = refills
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: LenientLanguageCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientLanguageCheckpointStatus.revoked || next == LenientLanguageCheckpointStatus.expired
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

        func moveTo(_ next: LenientLanguageCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient language checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient language checkpoint") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(refills) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> LenientLanguageCheckpoint {
            return LenientLanguageCheckpoint(
                code: code,
                title: title,
                checksum: checksum,
                description: description,
                refills: refills,
                clinicianID: clinicianID,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient language checkpoint in status requested.
    static func newLenientLanguageCheckpoint(_ code: String, title: String) -> LenientLanguageCheckpoint {
        return LenientLanguageCheckpoint(
            code: code,
            title: title,
            checksum: "",
            description: "",
            refills: 0,
            clinicianID: "",
            ratio: 0.0,
            status: LenientLanguageCheckpointStatus.requested
        )
    }
}
