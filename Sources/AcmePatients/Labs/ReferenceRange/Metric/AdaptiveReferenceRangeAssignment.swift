import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive reference range assignment is in its life cycle.
    enum AdaptiveReferenceRangeAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive reference range assignment as the reference range team keeps it.
    final class AdaptiveReferenceRangeAssignment {
        var code: String
        var name: String
        var expiresAt: Int
        var quantity: Int
        var facility: String
        var status: AdaptiveReferenceRangeAssignmentStatus

        init(code: String, name: String, expiresAt: Int, quantity: Int, facility: String, status: AdaptiveReferenceRangeAssignmentStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.quantity = quantity
            self.facility = facility
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

        func canMoveTo(_ next: AdaptiveReferenceRangeAssignmentStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveReferenceRangeAssignmentStatus.queued || next == AdaptiveReferenceRangeAssignmentStatus.running
            case .queued:
                return next == AdaptiveReferenceRangeAssignmentStatus.failed
            case .running:
                return next == AdaptiveReferenceRangeAssignmentStatus.done || next == AdaptiveReferenceRangeAssignmentStatus.failed
            case .done:
                return next == AdaptiveReferenceRangeAssignmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveReferenceRangeAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive reference range assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedValue() -> Double {
            return ((Double(quantity) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveReferenceRangeAssignment {
            return AdaptiveReferenceRangeAssignment(
                code: code,
                name: name,
                expiresAt: expiresAt,
                quantity: quantity,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a adaptive reference range assignment in status new.
    static func newAdaptiveReferenceRangeAssignment(_ code: String, name: String) -> AdaptiveReferenceRangeAssignment {
        return AdaptiveReferenceRangeAssignment(
            code: code,
            name: name,
            expiresAt: 0,
            quantity: 0,
            facility: "",
            status: AdaptiveReferenceRangeAssignmentStatus.new
        )
    }
}
