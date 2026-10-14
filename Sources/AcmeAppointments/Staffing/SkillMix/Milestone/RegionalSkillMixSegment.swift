import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional skill mix segment is in its life cycle.
    enum RegionalSkillMixSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A regional skill mix segment. Its code is unique within a tenant.
    final class RegionalSkillMixSegment {
        var code: String
        var title: String
        var currency: String
        var checksum: String
        var description: String
        var tags: [String]
        var clinicianID: String
        var active: Bool
        var amount: Double
        var status: RegionalSkillMixSegmentStatus

        init(code: String, title: String, currency: String, checksum: String, description: String, tags: [String], clinicianID: String, active: Bool, amount: Double, status: RegionalSkillMixSegmentStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.checksum = checksum
            self.description = description
            self.tags = tags
            self.clinicianID = clinicianID
            self.active = active
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalSkillMixSegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalSkillMixSegmentStatus.pending || next == RegionalSkillMixSegmentStatus.suspended
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RegionalSkillMixSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional skill mix segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RegionalSkillMixSegment {
            return RegionalSkillMixSegment(
                code: code,
                title: title,
                currency: currency,
                checksum: checksum,
                description: description,
                tags: tags,
                clinicianID: clinicianID,
                active: active,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional skill mix segment in status draft.
    static func newRegionalSkillMixSegment(_ code: String, title: String) -> RegionalSkillMixSegment {
        return RegionalSkillMixSegment(
            code: code,
            title: title,
            currency: "",
            checksum: "",
            description: "",
            tags: [],
            clinicianID: "",
            active: false,
            amount: 0.0,
            status: RegionalSkillMixSegmentStatus.draft
        )
    }
}
