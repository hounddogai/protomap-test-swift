import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient panel assignment is in its life cycle.
    enum LenientPanelAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A lenient panel assignment as the panel team keeps it.
    final class LenientPanelAssignment {
        var code: String
        var name: String
        var country: String
        var payer: String
        var weight: Double
        var status: LenientPanelAssignmentStatus

        init(code: String, name: String, country: String, payer: String, weight: Double, status: LenientPanelAssignmentStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.payer = payer
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientPanelAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == LenientPanelAssignmentStatus.warming || next == LenientPanelAssignmentStatus.draining
            case .warming:
                return next == LenientPanelAssignmentStatus.ready || next == LenientPanelAssignmentStatus.stopped
            case .ready:
                return next == LenientPanelAssignmentStatus.draining
            case .draining:
                return next == LenientPanelAssignmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientPanelAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient panel assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> LenientPanelAssignment {
            return LenientPanelAssignment(
                code: code,
                name: name,
                country: country,
                payer: payer,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a lenient panel assignment in status idle.
    static func newLenientPanelAssignment(_ code: String, name: String) -> LenientPanelAssignment {
        return LenientPanelAssignment(
            code: code,
            name: name,
            country: "",
            payer: "",
            weight: 0.0,
            status: LenientPanelAssignmentStatus.idle
        )
    }
}
