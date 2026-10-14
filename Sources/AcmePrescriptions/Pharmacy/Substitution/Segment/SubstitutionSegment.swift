import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution segment is in its life cycle.
    enum SubstitutionSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A substitution segment as the substitution team keeps it.
    final class SubstitutionSegment {
        var code: String
        var label: String
        var bed: String
        var expiresAt: Int
        var checksum: String
        var status: SubstitutionSegmentStatus

        init(code: String, label: String, bed: String, expiresAt: Int, checksum: String, status: SubstitutionSegmentStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.expiresAt = expiresAt
            self.checksum = checksum
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

        func canMoveTo(_ next: SubstitutionSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SubstitutionSegmentStatus.approved || next == SubstitutionSegmentStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: SubstitutionSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> SubstitutionSegment {
            return SubstitutionSegment(
                code: code,
                label: label,
                bed: bed,
                expiresAt: expiresAt,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a substitution segment in status proposed.
    static func newSubstitutionSegment(_ code: String, label: String) -> SubstitutionSegment {
        return SubstitutionSegment(
            code: code,
            label: label,
            bed: "",
            expiresAt: 0,
            checksum: "",
            status: SubstitutionSegmentStatus.proposed
        )
    }
}
