import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall preference is in its life cycle.
    enum RecallPreferenceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A recall preference as the recall team keeps it.
    final class RecallPreference {
        var code: String
        var label: String
        var limit: Int
        var updatedAt: Int
        var budget: Double
        var graceDays: Int
        var createdAt: Int
        var approved: Bool
        var refills: Int
        var status: RecallPreferenceStatus

        init(code: String, label: String, limit: Int, updatedAt: Int, budget: Double, graceDays: Int, createdAt: Int, approved: Bool, refills: Int, status: RecallPreferenceStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.updatedAt = updatedAt
            self.budget = budget
            self.graceDays = graceDays
            self.createdAt = createdAt
            self.approved = approved
            self.refills = refills
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

        func canMoveTo(_ next: RecallPreferenceStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == RecallPreferenceStatus.active || next == RecallPreferenceStatus.suspended
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RecallPreferenceStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("recall preference") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((budget + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> RecallPreference {
            return RecallPreference(
                code: code,
                label: label,
                limit: limit,
                updatedAt: updatedAt,
                budget: budget,
                graceDays: graceDays,
                createdAt: createdAt,
                approved: approved,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a recall preference in status draft.
    static func newRecallPreference(_ code: String, label: String) -> RecallPreference {
        return RecallPreference(
            code: code,
            label: label,
            limit: 0,
            updatedAt: 0,
            budget: 0.0,
            graceDays: 0,
            createdAt: 0,
            approved: false,
            refills: 0,
            status: RecallPreferenceStatus.draft
        )
    }
}
