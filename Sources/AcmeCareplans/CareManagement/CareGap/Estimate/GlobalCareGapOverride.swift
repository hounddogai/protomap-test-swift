import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global care gap override is in its life cycle.
    enum GlobalCareGapOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global care gap override. Its code is unique within a tenant.
    final class GlobalCareGapOverride {
        var code: String
        var name: String
        var revision: Int
        var cost: Double
        var margin: Double
        var limit: Int
        var archived: Bool
        var locale: String
        var score: Double
        var clinicianID: String
        var status: GlobalCareGapOverrideStatus

        init(code: String, name: String, revision: Int, cost: Double, margin: Double, limit: Int, archived: Bool, locale: String, score: Double, clinicianID: String, status: GlobalCareGapOverrideStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.cost = cost
            self.margin = margin
            self.limit = limit
            self.archived = archived
            self.locale = locale
            self.score = score
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: GlobalCareGapOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == GlobalCareGapOverrideStatus.reopened || next == GlobalCareGapOverrideStatus.archived
            case .resolved:
                return next == GlobalCareGapOverrideStatus.reopened || next == GlobalCareGapOverrideStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: GlobalCareGapOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global care gap override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("global care gap override") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((cost + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalCareGapOverride {
            return GlobalCareGapOverride(
                code: code,
                name: name,
                revision: revision,
                cost: cost,
                margin: margin,
                limit: limit,
                archived: archived,
                locale: locale,
                score: score,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global care gap override in status open.
    static func newGlobalCareGapOverride(_ code: String, name: String) -> GlobalCareGapOverride {
        return GlobalCareGapOverride(
            code: code,
            name: name,
            revision: 0,
            cost: 0.0,
            margin: 0.0,
            limit: 0,
            archived: false,
            locale: "",
            score: 0.0,
            clinicianID: "",
            status: GlobalCareGapOverrideStatus.`open`
        )
    }
}
