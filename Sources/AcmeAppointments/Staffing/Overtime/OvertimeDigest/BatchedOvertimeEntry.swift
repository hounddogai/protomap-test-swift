import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched overtime entry is in its life cycle.
    enum BatchedOvertimeEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched overtime entry. Its code is unique within a tenant.
    final class BatchedOvertimeEntry {
        var code: String
        var title: String
        var budget: Double
        var attributes: [String: String]
        var expiresAt: Int
        var refills: Int
        var country: String
        var floorValue: Double
        var label: String
        var status: BatchedOvertimeEntryStatus

        init(code: String, title: String, budget: Double, attributes: [String: String], expiresAt: Int, refills: Int, country: String, floorValue: Double, label: String, status: BatchedOvertimeEntryStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.attributes = attributes
            self.expiresAt = expiresAt
            self.refills = refills
            self.country = country
            self.floorValue = floorValue
            self.label = label
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

        func canMoveTo(_ next: BatchedOvertimeEntryStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == BatchedOvertimeEntryStatus.suspended || next == BatchedOvertimeEntryStatus.closed
            case .suspended:
                return next == BatchedOvertimeEntryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedOvertimeEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched overtime entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
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

        func weightedValue() -> Double {
            return (Double(expiresAt) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> BatchedOvertimeEntry {
            return BatchedOvertimeEntry(
                code: code,
                title: title,
                budget: budget,
                attributes: attributes,
                expiresAt: expiresAt,
                refills: refills,
                country: country,
                floorValue: floorValue,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched overtime entry in status draft.
    static func newBatchedOvertimeEntry(_ code: String, title: String) -> BatchedOvertimeEntry {
        return BatchedOvertimeEntry(
            code: code,
            title: title,
            budget: 0.0,
            attributes: [:],
            expiresAt: 0,
            refills: 0,
            country: "",
            floorValue: 0.0,
            label: "",
            status: BatchedOvertimeEntryStatus.draft
        )
    }
}
