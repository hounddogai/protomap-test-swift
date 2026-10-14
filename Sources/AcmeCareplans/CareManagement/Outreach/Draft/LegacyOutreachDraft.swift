import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy outreach draft is in its life cycle.
    enum LegacyOutreachDraftStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A legacy outreach draft as the outreach team keeps it.
    final class LegacyOutreachDraft {
        var code: String
        var name: String
        var attributes: [String: String]
        var dosageMg: Double
        var expiresAt: Int
        var status: LegacyOutreachDraftStatus

        init(code: String, name: String, attributes: [String: String], dosageMg: Double, expiresAt: Int, status: LegacyOutreachDraftStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.dosageMg = dosageMg
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyOutreachDraftStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LegacyOutreachDraftStatus.inProgress || next == LegacyOutreachDraftStatus.completed
            case .inProgress:
                return next == LegacyOutreachDraftStatus.cancelled
            case .completed:
                return next == LegacyOutreachDraftStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyOutreachDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy outreach draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netVolume() -> Double {
            return ((Double(expiresAt) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> LegacyOutreachDraft {
            return LegacyOutreachDraft(
                code: code,
                name: name,
                attributes: attributes,
                dosageMg: dosageMg,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy outreach draft in status planned.
    static func newLegacyOutreachDraft(_ code: String, name: String) -> LegacyOutreachDraft {
        return LegacyOutreachDraft(
            code: code,
            name: name,
            attributes: [:],
            dosageMg: 0.0,
            expiresAt: 0,
            status: LegacyOutreachDraftStatus.planned
        )
    }
}
