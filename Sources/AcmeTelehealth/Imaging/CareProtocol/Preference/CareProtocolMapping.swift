import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol mapping is in its life cycle.
    enum CareProtocolMappingStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A care protocol mapping as the care protocol team keeps it.
    final class CareProtocolMapping {
        var code: String
        var label: String
        var notes: String
        var facility: String
        var reviewer: String
        var pinned: Bool
        var budget: Double
        var status: CareProtocolMappingStatus

        init(code: String, label: String, notes: String, facility: String, reviewer: String, pinned: Bool, budget: Double, status: CareProtocolMappingStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.facility = facility
            self.reviewer = reviewer
            self.pinned = pinned
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolMappingStatus) -> Bool {
            switch status {
            case .requested:
                return next == CareProtocolMappingStatus.granted || next == CareProtocolMappingStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CareProtocolMappingStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> CareProtocolMapping {
            return CareProtocolMapping(
                code: code,
                label: label,
                notes: notes,
                facility: facility,
                reviewer: reviewer,
                pinned: pinned,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a care protocol mapping in status requested.
    static func newCareProtocolMapping(_ code: String, label: String) -> CareProtocolMapping {
        return CareProtocolMapping(
            code: code,
            label: label,
            notes: "",
            facility: "",
            reviewer: "",
            pinned: false,
            budget: 0.0,
            status: CareProtocolMappingStatus.requested
        )
    }
}
