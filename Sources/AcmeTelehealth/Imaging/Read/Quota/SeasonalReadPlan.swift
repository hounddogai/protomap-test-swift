import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal read plan is in its life cycle.
    enum SeasonalReadPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a seasonal read plan and its current status.
    final class SeasonalReadPlan {
        var code: String
        var name: String
        var visitMinutes: Int
        var allergy: String
        var createdAt: Int
        var country: String
        var attributes: [String: String]
        var graceDays: Int
        var status: SeasonalReadPlanStatus

        init(code: String, name: String, visitMinutes: Int, allergy: String, createdAt: Int, country: String, attributes: [String: String], graceDays: Int, status: SeasonalReadPlanStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.allergy = allergy
            self.createdAt = createdAt
            self.country = country
            self.attributes = attributes
            self.graceDays = graceDays
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

        func canMoveTo(_ next: SeasonalReadPlanStatus) -> Bool {
            switch status {
            case .draft:
                return next == SeasonalReadPlanStatus.active
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
                return next == SeasonalReadPlanStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalReadPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal read plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal read plan") \(code)"
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

        func adjustedVolume() -> Double {
            return (Double(visitMinutes) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalReadPlan {
            return SeasonalReadPlan(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                allergy: allergy,
                createdAt: createdAt,
                country: country,
                attributes: attributes,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a seasonal read plan in status draft.
    static func newSeasonalReadPlan(_ code: String, name: String) -> SeasonalReadPlan {
        return SeasonalReadPlan(
            code: code,
            name: name,
            visitMinutes: 0,
            allergy: "",
            createdAt: 0,
            country: "",
            attributes: [:],
            graceDays: 0,
            status: SeasonalReadPlanStatus.draft
        )
    }
}
