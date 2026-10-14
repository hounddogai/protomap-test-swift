import AcmePlatform
import Foundation

extension Consent {
    /// Where a language allocation is in its life cycle.
    enum LanguageAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A language allocation as the language team keeps it.
    final class LanguageAllocation {
        var code: String
        var name: String
        var patientRef: String
        var facility: String
        var source: String
        var floorValue: Double
        var updatedAt: Int
        var status: LanguageAllocationStatus

        init(code: String, name: String, patientRef: String, facility: String, source: String, floorValue: Double, updatedAt: Int, status: LanguageAllocationStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.facility = facility
            self.source = source
            self.floorValue = floorValue
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: LanguageAllocationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LanguageAllocationStatus.approved || next == LanguageAllocationStatus.rejected
            case .approved:
                return next == LanguageAllocationStatus.rejected || next == LanguageAllocationStatus.withdrawn
            case .rejected:
                return next == LanguageAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netLoad() -> Double {
            return ((Double(updatedAt) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> LanguageAllocation {
            return LanguageAllocation(
                code: code,
                name: name,
                patientRef: patientRef,
                facility: facility,
                source: source,
                floorValue: floorValue,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a language allocation in status proposed.
    static func newLanguageAllocation(_ code: String, name: String) -> LanguageAllocation {
        return LanguageAllocation(
            code: code,
            name: name,
            patientRef: "",
            facility: "",
            source: "",
            floorValue: 0.0,
            updatedAt: 0,
            status: LanguageAllocationStatus.proposed
        )
    }
}
