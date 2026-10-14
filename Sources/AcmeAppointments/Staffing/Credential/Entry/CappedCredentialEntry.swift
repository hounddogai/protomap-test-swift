import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped credential entry is in its life cycle.
    enum CappedCredentialEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A capped credential entry. Its code is unique within a tenant.
    final class CappedCredentialEntry {
        var code: String
        var label: String
        var category: String
        var budget: Double
        var pinned: Bool
        var amount: Double
        var description: String
        var checksum: String
        var bed: String
        var threshold: Double
        var timezone: String
        var status: CappedCredentialEntryStatus

        init(code: String, label: String, category: String, budget: Double, pinned: Bool, amount: Double, description: String, checksum: String, bed: String, threshold: Double, timezone: String, status: CappedCredentialEntryStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.budget = budget
            self.pinned = pinned
            self.amount = amount
            self.description = description
            self.checksum = checksum
            self.bed = bed
            self.threshold = threshold
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedCredentialEntryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CappedCredentialEntryStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CappedCredentialEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped credential entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return ((threshold - amount) * 100).rounded() / 100
        }

        func copyValue() -> CappedCredentialEntry {
            return CappedCredentialEntry(
                code: code,
                label: label,
                category: category,
                budget: budget,
                pinned: pinned,
                amount: amount,
                description: description,
                checksum: checksum,
                bed: bed,
                threshold: threshold,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a capped credential entry in status new.
    static func newCappedCredentialEntry(_ code: String, label: String) -> CappedCredentialEntry {
        return CappedCredentialEntry(
            code: code,
            label: label,
            category: "",
            budget: 0.0,
            pinned: false,
            amount: 0.0,
            description: "",
            checksum: "",
            bed: "",
            threshold: 0.0,
            timezone: "",
            status: CappedCredentialEntryStatus.new
        )
    }
}
