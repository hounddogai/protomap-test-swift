import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched dispense override is in its life cycle.
    enum BatchedDispenseOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched dispense override as the dispense team keeps it.
    final class BatchedDispenseOverride {
        var code: String
        var name: String
        var attributes: [String: String]
        var notes: String
        var cost: Double
        var dosageMg: Double
        var version: Int
        var status: BatchedDispenseOverrideStatus

        init(code: String, name: String, attributes: [String: String], notes: String, cost: Double, dosageMg: Double, version: Int, status: BatchedDispenseOverrideStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.notes = notes
            self.cost = cost
            self.dosageMg = dosageMg
            self.version = version
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

        func canMoveTo(_ next: BatchedDispenseOverrideStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == BatchedDispenseOverrideStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == BatchedDispenseOverrideStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedDispenseOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched dispense override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
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

        func adjustedTotal() -> Double {
            return ((dosageMg - cost) * 100).rounded() / 100
        }

        func copyValue() -> BatchedDispenseOverride {
            return BatchedDispenseOverride(
                code: code,
                name: name,
                attributes: attributes,
                notes: notes,
                cost: cost,
                dosageMg: dosageMg,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched dispense override in status draft.
    static func newBatchedDispenseOverride(_ code: String, name: String) -> BatchedDispenseOverride {
        return BatchedDispenseOverride(
            code: code,
            name: name,
            attributes: [:],
            notes: "",
            cost: 0.0,
            dosageMg: 0.0,
            version: 0,
            status: BatchedDispenseOverrideStatus.draft
        )
    }
}
