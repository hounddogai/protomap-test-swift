import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance entry is in its life cycle.
    enum RemittanceEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A remittance entry. Its code is unique within a tenant.
    final class RemittanceEntry {
        var code: String
        var name: String
        var reviewer: String
        var revision: Int
        var batchSize: Int
        var bed: String
        var windowDays: Int
        var status: RemittanceEntryStatus

        init(code: String, name: String, reviewer: String, revision: Int, batchSize: Int, bed: String, windowDays: Int, status: RemittanceEntryStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.revision = revision
            self.batchSize = batchSize
            self.bed = bed
            self.windowDays = windowDays
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

        func canMoveTo(_ next: RemittanceEntryStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == RemittanceEntryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceEntry {
            return RemittanceEntry(
                code: code,
                name: name,
                reviewer: reviewer,
                revision: revision,
                batchSize: batchSize,
                bed: bed,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a remittance entry in status proposed.
    static func newRemittanceEntry(_ code: String, name: String) -> RemittanceEntry {
        return RemittanceEntry(
            code: code,
            name: name,
            reviewer: "",
            revision: 0,
            batchSize: 0,
            bed: "",
            windowDays: 0,
            status: RemittanceEntryStatus.proposed
        )
    }
}
