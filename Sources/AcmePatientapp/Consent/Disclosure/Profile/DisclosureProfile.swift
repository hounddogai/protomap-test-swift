import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure profile is in its life cycle.
    enum DisclosureProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A disclosure profile as the disclosure team keeps it.
    final class DisclosureProfile {
        var code: String
        var name: String
        var retries: Int
        var maximum: Double
        var weight: Double
        var allergy: String
        var bed: String
        var checksum: String
        var pinned: Bool
        var updatedAt: Int
        var revision: Int
        var status: DisclosureProfileStatus

        init(code: String, name: String, retries: Int, maximum: Double, weight: Double, allergy: String, bed: String, checksum: String, pinned: Bool, updatedAt: Int, revision: Int, status: DisclosureProfileStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.maximum = maximum
            self.weight = weight
            self.allergy = allergy
            self.bed = bed
            self.checksum = checksum
            self.pinned = pinned
            self.updatedAt = updatedAt
            self.revision = revision
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

        func canMoveTo(_ next: DisclosureProfileStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DisclosureProfileStatus.archived
            case .inReview:
                return next == DisclosureProfileStatus.resolved || next == DisclosureProfileStatus.reopened
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == DisclosureProfileStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netVolume() -> Double {
            return ((weight + maximum) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureProfile {
            return DisclosureProfile(
                code: code,
                name: name,
                retries: retries,
                maximum: maximum,
                weight: weight,
                allergy: allergy,
                bed: bed,
                checksum: checksum,
                pinned: pinned,
                updatedAt: updatedAt,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a disclosure profile in status open.
    static func newDisclosureProfile(_ code: String, name: String) -> DisclosureProfile {
        return DisclosureProfile(
            code: code,
            name: name,
            retries: 0,
            maximum: 0.0,
            weight: 0.0,
            allergy: "",
            bed: "",
            checksum: "",
            pinned: false,
            updatedAt: 0,
            revision: 0,
            status: DisclosureProfileStatus.`open`
        )
    }
}
