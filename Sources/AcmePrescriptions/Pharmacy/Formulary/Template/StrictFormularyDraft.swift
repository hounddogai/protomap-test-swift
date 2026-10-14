import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict formulary draft is in its life cycle.
    enum StrictFormularyDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a strict formulary draft and its current status.
    final class StrictFormularyDraft {
        var code: String
        var title: String
        var updatedAt: Int
        var attributes: [String: String]
        var refills: Int
        var ceiling: Double
        var status: StrictFormularyDraftStatus

        init(code: String, title: String, updatedAt: Int, attributes: [String: String], refills: Int, ceiling: Double, status: StrictFormularyDraftStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.attributes = attributes
            self.refills = refills
            self.ceiling = ceiling
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

        func canMoveTo(_ next: StrictFormularyDraftStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictFormularyDraftStatus.suspended || next == StrictFormularyDraftStatus.closed
            case .pending:
                switch next {
                case .active:
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

        func moveTo(_ next: StrictFormularyDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict formulary draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
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

        func effectiveExposure() -> Double {
            return ((Double(refills) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictFormularyDraft {
            return StrictFormularyDraft(
                code: code,
                title: title,
                updatedAt: updatedAt,
                attributes: attributes,
                refills: refills,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict formulary draft in status draft.
    static func newStrictFormularyDraft(_ code: String, title: String) -> StrictFormularyDraft {
        return StrictFormularyDraft(
            code: code,
            title: title,
            updatedAt: 0,
            attributes: [:],
            refills: 0,
            ceiling: 0.0,
            status: StrictFormularyDraftStatus.draft
        )
    }
}
