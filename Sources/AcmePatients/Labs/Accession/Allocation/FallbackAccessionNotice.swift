import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback accession notice is in its life cycle.
    enum FallbackAccessionNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback accession notice as the accession team keeps it.
    final class FallbackAccessionNotice {
        var code: String
        var name: String
        var locale: String
        var notes: String
        var patientRef: String
        var approved: Bool
        var score: Double
        var status: FallbackAccessionNoticeStatus

        init(code: String, name: String, locale: String, notes: String, patientRef: String, approved: Bool, score: Double, status: FallbackAccessionNoticeStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.notes = notes
            self.patientRef = patientRef
            self.approved = approved
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

        func canMoveTo(_ next: FallbackAccessionNoticeStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
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

        func moveTo(_ next: FallbackAccessionNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback accession notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback accession notice") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> FallbackAccessionNotice {
            return FallbackAccessionNotice(
                code: code,
                name: name,
                locale: locale,
                notes: notes,
                patientRef: patientRef,
                approved: approved,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a fallback accession notice in status requested.
    static func newFallbackAccessionNotice(_ code: String, name: String) -> FallbackAccessionNotice {
        return FallbackAccessionNotice(
            code: code,
            name: name,
            locale: "",
            notes: "",
            patientRef: "",
            approved: false,
            score: 0.0,
            status: FallbackAccessionNoticeStatus.requested
        )
    }
}
