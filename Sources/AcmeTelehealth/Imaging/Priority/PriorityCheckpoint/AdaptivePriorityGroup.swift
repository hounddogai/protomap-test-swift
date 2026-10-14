import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive priority group is in its life cycle.
    enum AdaptivePriorityGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a adaptive priority group and its current status.
    final class AdaptivePriorityGroup {
        var code: String
        var label: String
        var endsAt: Int
        var currency: String
        var discount: Double
        var unit: String
        var source: String
        var floorValue: Double
        var procedureCode: String
        var status: AdaptivePriorityGroupStatus

        init(code: String, label: String, endsAt: Int, currency: String, discount: Double, unit: String, source: String, floorValue: Double, procedureCode: String, status: AdaptivePriorityGroupStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.currency = currency
            self.discount = discount
            self.unit = unit
            self.source = source
            self.floorValue = floorValue
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: AdaptivePriorityGroupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AdaptivePriorityGroupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptivePriorityGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive priority group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedExposure() -> Double {
            return ((discount - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> AdaptivePriorityGroup {
            return AdaptivePriorityGroup(
                code: code,
                label: label,
                endsAt: endsAt,
                currency: currency,
                discount: discount,
                unit: unit,
                source: source,
                floorValue: floorValue,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive priority group in status idle.
    static func newAdaptivePriorityGroup(_ code: String, label: String) -> AdaptivePriorityGroup {
        return AdaptivePriorityGroup(
            code: code,
            label: label,
            endsAt: 0,
            currency: "",
            discount: 0.0,
            unit: "",
            source: "",
            floorValue: 0.0,
            procedureCode: "",
            status: AdaptivePriorityGroupStatus.idle
        )
    }
}
