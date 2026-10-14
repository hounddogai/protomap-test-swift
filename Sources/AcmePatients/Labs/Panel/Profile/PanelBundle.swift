import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel bundle is in its life cycle.
    enum PanelBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a panel bundle and its current status.
    final class PanelBundle {
        var code: String
        var name: String
        var category: String
        var region: String
        var locale: String
        var externalRef: String
        var budget: Double
        var archived: Bool
        var notes: String
        var endsAt: Int
        var status: PanelBundleStatus

        init(code: String, name: String, category: String, region: String, locale: String, externalRef: String, budget: Double, archived: Bool, notes: String, endsAt: Int, status: PanelBundleStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.region = region
            self.locale = locale
            self.externalRef = externalRef
            self.budget = budget
            self.archived = archived
            self.notes = notes
            self.endsAt = endsAt
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

        func canMoveTo(_ next: PanelBundleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PanelBundleStatus.withdrawn
            case .approved:
                return next == PanelBundleStatus.rejected
            case .rejected:
                return next == PanelBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedLoad() -> Double {
            return ((Double(endsAt) - budget) * 100).rounded() / 100
        }

        func copyValue() -> PanelBundle {
            return PanelBundle(
                code: code,
                name: name,
                category: category,
                region: region,
                locale: locale,
                externalRef: externalRef,
                budget: budget,
                archived: archived,
                notes: notes,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a panel bundle in status proposed.
    static func newPanelBundle(_ code: String, name: String) -> PanelBundle {
        return PanelBundle(
            code: code,
            name: name,
            category: "",
            region: "",
            locale: "",
            externalRef: "",
            budget: 0.0,
            archived: false,
            notes: "",
            endsAt: 0,
            status: PanelBundleStatus.proposed
        )
    }
}
