import AcmePlatform
import Foundation

extension Referrals {
    /// Where a primary slot rollup is in its life cycle.
    enum PrimarySlotRollupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a primary slot rollup and its current status.
    final class PrimarySlotRollup {
        var code: String
        var name: String
        var attempts: Int
        var updatedAt: Int
        var ceiling: Double
        var discount: Double
        var maximum: Double
        var status: PrimarySlotRollupStatus

        init(code: String, name: String, attempts: Int, updatedAt: Int, ceiling: Double, discount: Double, maximum: Double, status: PrimarySlotRollupStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.updatedAt = updatedAt
            self.ceiling = ceiling
            self.discount = discount
            self.maximum = maximum
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

        func canMoveTo(_ next: PrimarySlotRollupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PrimarySlotRollupStatus.done || next == PrimarySlotRollupStatus.failed
            case .running:
                return next == PrimarySlotRollupStatus.done
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

        func moveTo(_ next: PrimarySlotRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary slot rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return (Double(updatedAt) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> PrimarySlotRollup {
            return PrimarySlotRollup(
                code: code,
                name: name,
                attempts: attempts,
                updatedAt: updatedAt,
                ceiling: ceiling,
                discount: discount,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary slot rollup in status new.
    static func newPrimarySlotRollup(_ code: String, name: String) -> PrimarySlotRollup {
        return PrimarySlotRollup(
            code: code,
            name: name,
            attempts: 0,
            updatedAt: 0,
            ceiling: 0.0,
            discount: 0.0,
            maximum: 0.0,
            status: PrimarySlotRollupStatus.new
        )
    }
}
