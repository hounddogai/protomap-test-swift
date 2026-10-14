import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual specimen override is in its life cycle.
    enum ManualSpecimenOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a manual specimen override and its current status.
    final class ManualSpecimenOverride {
        var code: String
        var label: String
        var priority: Int
        var minimum: Double
        var quantity: Int
        var segment: String
        var summary: String
        var expiresAt: Int
        var category: String
        var status: ManualSpecimenOverrideStatus

        init(code: String, label: String, priority: Int, minimum: Double, quantity: Int, segment: String, summary: String, expiresAt: Int, category: String, status: ManualSpecimenOverrideStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.minimum = minimum
            self.quantity = quantity
            self.segment = segment
            self.summary = summary
            self.expiresAt = expiresAt
            self.category = category
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

        func canMoveTo(_ next: ManualSpecimenOverrideStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ManualSpecimenOverrideStatus.active
            case .active:
                return next == ManualSpecimenOverrideStatus.suspended || next == ManualSpecimenOverrideStatus.closed
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

        func moveTo(_ next: ManualSpecimenOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual specimen override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedValue() -> Double {
            return ((Double(quantity) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ManualSpecimenOverride {
            return ManualSpecimenOverride(
                code: code,
                label: label,
                priority: priority,
                minimum: minimum,
                quantity: quantity,
                segment: segment,
                summary: summary,
                expiresAt: expiresAt,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual specimen override in status draft.
    static func newManualSpecimenOverride(_ code: String, label: String) -> ManualSpecimenOverride {
        return ManualSpecimenOverride(
            code: code,
            label: label,
            priority: 0,
            minimum: 0.0,
            quantity: 0,
            segment: "",
            summary: "",
            expiresAt: 0,
            category: "",
            status: ManualSpecimenOverrideStatus.draft
        )
    }
}
