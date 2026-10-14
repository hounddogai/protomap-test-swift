import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure rollup is in its life cycle.
    enum DisclosureRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One disclosure rollup, with what the planners need to act on it.
    final class DisclosureRollup {
        var code: String
        var name: String
        var dosageMg: Double
        var allergy: String
        var country: String
        var visitMinutes: Int
        var createdAt: Int
        var rate: Double
        var cost: Double
        var title: String
        var status: DisclosureRollupStatus

        init(code: String, name: String, dosageMg: Double, allergy: String, country: String, visitMinutes: Int, createdAt: Int, rate: Double, cost: Double, title: String, status: DisclosureRollupStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.allergy = allergy
            self.country = country
            self.visitMinutes = visitMinutes
            self.createdAt = createdAt
            self.rate = rate
            self.cost = cost
            self.title = title
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

        func canMoveTo(_ next: DisclosureRollupStatus) -> Bool {
            switch status {
            case .draft:
                return next == DisclosureRollupStatus.pending || next == DisclosureRollupStatus.closed
            case .pending:
                return next == DisclosureRollupStatus.active || next == DisclosureRollupStatus.closed
            case .active:
                return next == DisclosureRollupStatus.suspended || next == DisclosureRollupStatus.closed
            case .suspended:
                return next == DisclosureRollupStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DisclosureRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return ((cost + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureRollup {
            return DisclosureRollup(
                code: code,
                name: name,
                dosageMg: dosageMg,
                allergy: allergy,
                country: country,
                visitMinutes: visitMinutes,
                createdAt: createdAt,
                rate: rate,
                cost: cost,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a disclosure rollup in status draft.
    static func newDisclosureRollup(_ code: String, name: String) -> DisclosureRollup {
        return DisclosureRollup(
            code: code,
            name: name,
            dosageMg: 0.0,
            allergy: "",
            country: "",
            visitMinutes: 0,
            createdAt: 0,
            rate: 0.0,
            cost: 0.0,
            title: "",
            status: DisclosureRollupStatus.draft
        )
    }
}
