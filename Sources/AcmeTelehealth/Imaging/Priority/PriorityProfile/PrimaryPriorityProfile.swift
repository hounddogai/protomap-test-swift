import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary priority profile is in its life cycle.
    enum PrimaryPriorityProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary priority profile. Its code is unique within a tenant.
    final class PrimaryPriorityProfile {
        var code: String
        var name: String
        var clinicianID: String
        var quantity: Int
        var ceiling: Double
        var windowDays: Int
        var graceDays: Int
        var status: PrimaryPriorityProfileStatus

        init(code: String, name: String, clinicianID: String, quantity: Int, ceiling: Double, windowDays: Int, graceDays: Int, status: PrimaryPriorityProfileStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.quantity = quantity
            self.ceiling = ceiling
            self.windowDays = windowDays
            self.graceDays = graceDays
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

        func canMoveTo(_ next: PrimaryPriorityProfileStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimaryPriorityProfileStatus.running || next == PrimaryPriorityProfileStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimaryPriorityProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary priority profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveExposure() -> Double {
            return ((Double(graceDays) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryPriorityProfile {
            return PrimaryPriorityProfile(
                code: code,
                name: name,
                clinicianID: clinicianID,
                quantity: quantity,
                ceiling: ceiling,
                windowDays: windowDays,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary priority profile in status new.
    static func newPrimaryPriorityProfile(_ code: String, name: String) -> PrimaryPriorityProfile {
        return PrimaryPriorityProfile(
            code: code,
            name: name,
            clinicianID: "",
            quantity: 0,
            ceiling: 0.0,
            windowDays: 0,
            graceDays: 0,
            status: PrimaryPriorityProfileStatus.new
        )
    }
}
