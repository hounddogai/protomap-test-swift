import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census cycle is in its life cycle.
    enum CensusCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A census cycle. Its code is unique within a tenant.
    final class CensusCycle {
        var code: String
        var name: String
        var label: String
        var ownerID: String
        var refills: Int
        var priority: Int
        var dosageMg: Double
        var clinicianID: String
        var attributes: [String: String]
        var status: CensusCycleStatus

        init(code: String, name: String, label: String, ownerID: String, refills: Int, priority: Int, dosageMg: Double, clinicianID: String, attributes: [String: String], status: CensusCycleStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.ownerID = ownerID
            self.refills = refills
            self.priority = priority
            self.dosageMg = dosageMg
            self.clinicianID = clinicianID
            self.attributes = attributes
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

        func canMoveTo(_ next: CensusCycleStatus) -> Bool {
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
                return next == CensusCycleStatus.inProgress
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CensusCycleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("census cycle") \(code)"
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

        func effectiveTotal() -> Double {
            return ((Double(priority) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> CensusCycle {
            return CensusCycle(
                code: code,
                name: name,
                label: label,
                ownerID: ownerID,
                refills: refills,
                priority: priority,
                dosageMg: dosageMg,
                clinicianID: clinicianID,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a census cycle in status planned.
    static func newCensusCycle(_ code: String, name: String) -> CensusCycle {
        return CensusCycle(
            code: code,
            name: name,
            label: "",
            ownerID: "",
            refills: 0,
            priority: 0,
            dosageMg: 0.0,
            clinicianID: "",
            attributes: [:],
            status: CensusCycleStatus.planned
        )
    }
}
