import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy language review is in its life cycle.
    enum LegacyLanguageReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A legacy language review. Its code is unique within a tenant.
    final class LegacyLanguageReview {
        var code: String
        var name: String
        var windowDays: Int
        var description: String
        var unit: String
        var limit: Int
        var archived: Bool
        var status: LegacyLanguageReviewStatus

        init(code: String, name: String, windowDays: Int, description: String, unit: String, limit: Int, archived: Bool, status: LegacyLanguageReviewStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.description = description
            self.unit = unit
            self.limit = limit
            self.archived = archived
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

        func canMoveTo(_ next: LegacyLanguageReviewStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyLanguageReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy language review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy language review") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(limit) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyLanguageReview {
            return LegacyLanguageReview(
                code: code,
                name: name,
                windowDays: windowDays,
                description: description,
                unit: unit,
                limit: limit,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy language review in status draft.
    static func newLegacyLanguageReview(_ code: String, name: String) -> LegacyLanguageReview {
        return LegacyLanguageReview(
            code: code,
            name: name,
            windowDays: 0,
            description: "",
            unit: "",
            limit: 0,
            archived: false,
            status: LegacyLanguageReviewStatus.draft
        )
    }
}
