import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default substitution exception is in its life cycle.
    enum DefaultSubstitutionExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default substitution exception. Its code is unique within a tenant.
    final class DefaultSubstitutionException {
        var code: String
        var label: String
        var minimum: Double
        var ceiling: Double
        var capacity: Int
        var rate: Double
        var facility: String
        var unit: String
        var visible: Bool
        var status: DefaultSubstitutionExceptionStatus

        init(code: String, label: String, minimum: Double, ceiling: Double, capacity: Int, rate: Double, facility: String, unit: String, visible: Bool, status: DefaultSubstitutionExceptionStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.ceiling = ceiling
            self.capacity = capacity
            self.rate = rate
            self.facility = facility
            self.unit = unit
            self.visible = visible
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

        func canMoveTo(_ next: DefaultSubstitutionExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == DefaultSubstitutionExceptionStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DefaultSubstitutionExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default substitution exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedLoad() -> Double {
            return ((rate - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> DefaultSubstitutionException {
            return DefaultSubstitutionException(
                code: code,
                label: label,
                minimum: minimum,
                ceiling: ceiling,
                capacity: capacity,
                rate: rate,
                facility: facility,
                unit: unit,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a default substitution exception in status idle.
    static func newDefaultSubstitutionException(_ code: String, label: String) -> DefaultSubstitutionException {
        return DefaultSubstitutionException(
            code: code,
            label: label,
            minimum: 0.0,
            ceiling: 0.0,
            capacity: 0,
            rate: 0.0,
            facility: "",
            unit: "",
            visible: false,
            status: DefaultSubstitutionExceptionStatus.idle
        )
    }
}
