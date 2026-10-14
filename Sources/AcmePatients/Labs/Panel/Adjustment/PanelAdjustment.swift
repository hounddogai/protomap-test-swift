import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel adjustment is in its life cycle.
    enum PanelAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One panel adjustment, with what the planners need to act on it.
    final class PanelAdjustment {
        var code: String
        var name: String
        var externalRef: String
        var source: String
        var specialty: String
        var budget: Double
        var durationMinutes: Int
        var status: PanelAdjustmentStatus

        init(code: String, name: String, externalRef: String, source: String, specialty: String, budget: Double, durationMinutes: Int, status: PanelAdjustmentStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.source = source
            self.specialty = specialty
            self.budget = budget
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: PanelAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                return next == PanelAdjustmentStatus.running || next == PanelAdjustmentStatus.done
            case .queued:
                return next == PanelAdjustmentStatus.running || next == PanelAdjustmentStatus.done
            case .running:
                return next == PanelAdjustmentStatus.done || next == PanelAdjustmentStatus.failed
            case .done:
                return next == PanelAdjustmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return ((budget + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PanelAdjustment {
            return PanelAdjustment(
                code: code,
                name: name,
                externalRef: externalRef,
                source: source,
                specialty: specialty,
                budget: budget,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a panel adjustment in status new.
    static func newPanelAdjustment(_ code: String, name: String) -> PanelAdjustment {
        return PanelAdjustment(
            code: code,
            name: name,
            externalRef: "",
            source: "",
            specialty: "",
            budget: 0.0,
            durationMinutes: 0,
            status: PanelAdjustmentStatus.new
        )
    }
}
