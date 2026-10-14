import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution bundle is in its life cycle.
    enum SubstitutionBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One substitution bundle, with what the planners need to act on it.
    final class SubstitutionBundle {
        var code: String
        var name: String
        var tags: [String]
        var ward: String
        var limit: Int
        var title: String
        var weight: Double
        var archived: Bool
        var reviewer: String
        var checksum: String
        var region: String
        var status: SubstitutionBundleStatus

        init(code: String, name: String, tags: [String], ward: String, limit: Int, title: String, weight: Double, archived: Bool, reviewer: String, checksum: String, region: String, status: SubstitutionBundleStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.ward = ward
            self.limit = limit
            self.title = title
            self.weight = weight
            self.archived = archived
            self.reviewer = reviewer
            self.checksum = checksum
            self.region = region
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

        func canMoveTo(_ next: SubstitutionBundleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SubstitutionBundleStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: SubstitutionBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return (Double(limit) * weight * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionBundle {
            return SubstitutionBundle(
                code: code,
                name: name,
                tags: tags,
                ward: ward,
                limit: limit,
                title: title,
                weight: weight,
                archived: archived,
                reviewer: reviewer,
                checksum: checksum,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a substitution bundle in status proposed.
    static func newSubstitutionBundle(_ code: String, name: String) -> SubstitutionBundle {
        return SubstitutionBundle(
            code: code,
            name: name,
            tags: [],
            ward: "",
            limit: 0,
            title: "",
            weight: 0.0,
            archived: false,
            reviewer: "",
            checksum: "",
            region: "",
            status: SubstitutionBundleStatus.proposed
        )
    }
}
