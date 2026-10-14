import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending order set group is in its life cycle.
    enum PendingOrderSetGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending order set group. Its code is unique within a tenant.
    final class PendingOrderSetGroup {
        var code: String
        var label: String
        var phone: String
        var unit: String
        var ward: String
        var score: Double
        var status: PendingOrderSetGroupStatus

        init(code: String, label: String, phone: String, unit: String, ward: String, score: Double, status: PendingOrderSetGroupStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.unit = unit
            self.ward = ward
            self.score = score
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

        func canMoveTo(_ next: PendingOrderSetGroupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == PendingOrderSetGroupStatus.draining || next == PendingOrderSetGroupStatus.stopped
            case .draining:
                return next == PendingOrderSetGroupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingOrderSetGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending order set group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> PendingOrderSetGroup {
            return PendingOrderSetGroup(
                code: code,
                label: label,
                phone: phone,
                unit: unit,
                ward: ward,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending order set group in status idle.
    static func newPendingOrderSetGroup(_ code: String, label: String) -> PendingOrderSetGroup {
        return PendingOrderSetGroup(
            code: code,
            label: label,
            phone: "",
            unit: "",
            ward: "",
            score: 0.0,
            status: PendingOrderSetGroupStatus.idle
        )
    }
}
