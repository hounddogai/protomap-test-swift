import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction tier is in its life cycle.
    enum InteractionTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a interaction tier and its current status.
    final class InteractionTier {
        var code: String
        var label: String
        var refills: Int
        var graceDays: Int
        var acuity: Int
        var notes: String
        var timezone: String
        var margin: Double
        var capacity: Int
        var status: InteractionTierStatus

        init(code: String, label: String, refills: Int, graceDays: Int, acuity: Int, notes: String, timezone: String, margin: Double, capacity: Int, status: InteractionTierStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.graceDays = graceDays
            self.acuity = acuity
            self.notes = notes
            self.timezone = timezone
            self.margin = margin
            self.capacity = capacity
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

        func canMoveTo(_ next: InteractionTierStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
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
                return next == InteractionTierStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedValue() -> Double {
            return ((Double(refills) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionTier {
            return InteractionTier(
                code: code,
                label: label,
                refills: refills,
                graceDays: graceDays,
                acuity: acuity,
                notes: notes,
                timezone: timezone,
                margin: margin,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a interaction tier in status new.
    static func newInteractionTier(_ code: String, label: String) -> InteractionTier {
        return InteractionTier(
            code: code,
            label: label,
            refills: 0,
            graceDays: 0,
            acuity: 0,
            notes: "",
            timezone: "",
            margin: 0.0,
            capacity: 0,
            status: InteractionTierStatus.new
        )
    }
}
