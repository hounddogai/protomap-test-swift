import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession group is in its life cycle.
    enum AccessionGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A accession group as the accession team keeps it.
    final class AccessionGroup {
        var code: String
        var label: String
        var revision: Int
        var diagnosisCode: String
        var refills: Int
        var attempts: Int
        var status: AccessionGroupStatus

        init(code: String, label: String, revision: Int, diagnosisCode: String, refills: Int, attempts: Int, status: AccessionGroupStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.diagnosisCode = diagnosisCode
            self.refills = refills
            self.attempts = attempts
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

        func canMoveTo(_ next: AccessionGroupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == AccessionGroupStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedValue() -> Double {
            return ((Double(revision) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionGroup {
            return AccessionGroup(
                code: code,
                label: label,
                revision: revision,
                diagnosisCode: diagnosisCode,
                refills: refills,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a accession group in status requested.
    static func newAccessionGroup(_ code: String, label: String) -> AccessionGroup {
        return AccessionGroup(
            code: code,
            label: label,
            revision: 0,
            diagnosisCode: "",
            refills: 0,
            attempts: 0,
            status: AccessionGroupStatus.requested
        )
    }
}
