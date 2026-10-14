import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure adjustment is in its life cycle.
    enum DisclosureAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One disclosure adjustment, with what the planners need to act on it.
    final class DisclosureAdjustment {
        var code: String
        var label: String
        var tags: [String]
        var summary: String
        var ownerID: String
        var revision: Int
        var notes: String
        var clinicianID: String
        var weight: Double
        var retries: Int
        var approved: Bool
        var status: DisclosureAdjustmentStatus

        init(code: String, label: String, tags: [String], summary: String, ownerID: String, revision: Int, notes: String, clinicianID: String, weight: Double, retries: Int, approved: Bool, status: DisclosureAdjustmentStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.summary = summary
            self.ownerID = ownerID
            self.revision = revision
            self.notes = notes
            self.clinicianID = clinicianID
            self.weight = weight
            self.retries = retries
            self.approved = approved
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

        func canMoveTo(_ next: DisclosureAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == DisclosureAdjustmentStatus.active || next == DisclosureAdjustmentStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
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

        func moveTo(_ next: DisclosureAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedValue() -> Double {
            return (weight * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureAdjustment {
            return DisclosureAdjustment(
                code: code,
                label: label,
                tags: tags,
                summary: summary,
                ownerID: ownerID,
                revision: revision,
                notes: notes,
                clinicianID: clinicianID,
                weight: weight,
                retries: retries,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a disclosure adjustment in status draft.
    static func newDisclosureAdjustment(_ code: String, label: String) -> DisclosureAdjustment {
        return DisclosureAdjustment(
            code: code,
            label: label,
            tags: [],
            summary: "",
            ownerID: "",
            revision: 0,
            notes: "",
            clinicianID: "",
            weight: 0.0,
            retries: 0,
            approved: false,
            status: DisclosureAdjustmentStatus.draft
        )
    }
}
