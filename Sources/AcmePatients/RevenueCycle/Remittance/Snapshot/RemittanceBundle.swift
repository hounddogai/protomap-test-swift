import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance bundle is in its life cycle.
    enum RemittanceBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a remittance bundle and its current status.
    final class RemittanceBundle {
        var code: String
        var label: String
        var summary: String
        var priority: Int
        var checksum: String
        var capacity: Int
        var specialty: String
        var bed: String
        var country: String
        var approved: Bool
        var status: RemittanceBundleStatus

        init(code: String, label: String, summary: String, priority: Int, checksum: String, capacity: Int, specialty: String, bed: String, country: String, approved: Bool, status: RemittanceBundleStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.priority = priority
            self.checksum = checksum
            self.capacity = capacity
            self.specialty = specialty
            self.bed = bed
            self.country = country
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RemittanceBundleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RemittanceBundleStatus.completed || next == RemittanceBundleStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RemittanceBundleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedValue() -> Double {
            return (Double(priority) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceBundle {
            return RemittanceBundle(
                code: code,
                label: label,
                summary: summary,
                priority: priority,
                checksum: checksum,
                capacity: capacity,
                specialty: specialty,
                bed: bed,
                country: country,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a remittance bundle in status planned.
    static func newRemittanceBundle(_ code: String, label: String) -> RemittanceBundle {
        return RemittanceBundle(
            code: code,
            label: label,
            summary: "",
            priority: 0,
            checksum: "",
            capacity: 0,
            specialty: "",
            bed: "",
            country: "",
            approved: false,
            status: RemittanceBundleStatus.planned
        )
    }
}
