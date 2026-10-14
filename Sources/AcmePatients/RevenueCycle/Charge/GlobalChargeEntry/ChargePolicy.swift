import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge policy is in its life cycle.
    enum ChargePolicyStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One charge policy, with what the planners need to act on it.
    final class ChargePolicy {
        var code: String
        var label: String
        var windowDays: Int
        var updatedAt: Int
        var capacity: Int
        var visible: Bool
        var clinicianID: String
        var unit: String
        var revision: Int
        var payer: String
        var segment: String
        var status: ChargePolicyStatus

        init(code: String, label: String, windowDays: Int, updatedAt: Int, capacity: Int, visible: Bool, clinicianID: String, unit: String, revision: Int, payer: String, segment: String, status: ChargePolicyStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.updatedAt = updatedAt
            self.capacity = capacity
            self.visible = visible
            self.clinicianID = clinicianID
            self.unit = unit
            self.revision = revision
            self.payer = payer
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ChargePolicyStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ChargePolicyStatus.inProgress || next == ChargePolicyStatus.completed
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ChargePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return ((Double(revision) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> ChargePolicy {
            return ChargePolicy(
                code: code,
                label: label,
                windowDays: windowDays,
                updatedAt: updatedAt,
                capacity: capacity,
                visible: visible,
                clinicianID: clinicianID,
                unit: unit,
                revision: revision,
                payer: payer,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a charge policy in status planned.
    static func newChargePolicy(_ code: String, label: String) -> ChargePolicy {
        return ChargePolicy(
            code: code,
            label: label,
            windowDays: 0,
            updatedAt: 0,
            capacity: 0,
            visible: false,
            clinicianID: "",
            unit: "",
            revision: 0,
            payer: "",
            segment: "",
            status: ChargePolicyStatus.planned
        )
    }
}
