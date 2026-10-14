import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure profile is in its life cycle.
    enum ClosureProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One closure profile, with what the planners need to act on it.
    final class ClosureProfile {
        var code: String
        var title: String
        var windowDays: Int
        var batchSize: Int
        var unit: String
        var phone: String
        var pinned: Bool
        var cost: Double
        var dosageMg: Double
        var discount: Double
        var status: ClosureProfileStatus

        init(code: String, title: String, windowDays: Int, batchSize: Int, unit: String, phone: String, pinned: Bool, cost: Double, dosageMg: Double, discount: Double, status: ClosureProfileStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.batchSize = batchSize
            self.unit = unit
            self.phone = phone
            self.pinned = pinned
            self.cost = cost
            self.dosageMg = dosageMg
            self.discount = discount
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

        func canMoveTo(_ next: ClosureProfileStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ClosureProfileStatus.done
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: ClosureProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedValue() -> Double {
            return ((cost - discount) * 100).rounded() / 100
        }

        func copyValue() -> ClosureProfile {
            return ClosureProfile(
                code: code,
                title: title,
                windowDays: windowDays,
                batchSize: batchSize,
                unit: unit,
                phone: phone,
                pinned: pinned,
                cost: cost,
                dosageMg: dosageMg,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a closure profile in status new.
    static func newClosureProfile(_ code: String, title: String) -> ClosureProfile {
        return ClosureProfile(
            code: code,
            title: title,
            windowDays: 0,
            batchSize: 0,
            unit: "",
            phone: "",
            pinned: false,
            cost: 0.0,
            dosageMg: 0.0,
            discount: 0.0,
            status: ClosureProfileStatus.new
        )
    }
}
