import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program window is in its life cycle.
    enum ProgramWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A program window. Its code is unique within a tenant.
    final class ProgramWindow {
        var code: String
        var name: String
        var amount: Double
        var unit: String
        var maximum: Double
        var retries: Int
        var updatedAt: Int
        var label: String
        var visible: Bool
        var startsAt: Int
        var status: ProgramWindowStatus

        init(code: String, name: String, amount: Double, unit: String, maximum: Double, retries: Int, updatedAt: Int, label: String, visible: Bool, startsAt: Int, status: ProgramWindowStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.unit = unit
            self.maximum = maximum
            self.retries = retries
            self.updatedAt = updatedAt
            self.label = label
            self.visible = visible
            self.startsAt = startsAt
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

        func canMoveTo(_ next: ProgramWindowStatus) -> Bool {
            switch status {
            case .new:
                return next == ProgramWindowStatus.running || next == ProgramWindowStatus.done
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ProgramWindowStatus.done
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

        func moveTo(_ next: ProgramWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func weightedExposure() -> Double {
            return ((Double(retries) + amount) * 100).rounded() / 100
        }

        func copyValue() -> ProgramWindow {
            return ProgramWindow(
                code: code,
                name: name,
                amount: amount,
                unit: unit,
                maximum: maximum,
                retries: retries,
                updatedAt: updatedAt,
                label: label,
                visible: visible,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a program window in status new.
    static func newProgramWindow(_ code: String, name: String) -> ProgramWindow {
        return ProgramWindow(
            code: code,
            name: name,
            amount: 0.0,
            unit: "",
            maximum: 0.0,
            retries: 0,
            updatedAt: 0,
            label: "",
            visible: false,
            startsAt: 0,
            status: ProgramWindowStatus.new
        )
    }
}
