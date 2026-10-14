import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense override is in its life cycle.
    enum DispenseOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A dispense override. Its code is unique within a tenant.
    final class DispenseOverride {
        var code: String
        var label: String
        var externalRef: String
        var discount: Double
        var capacity: Int
        var status: DispenseOverrideStatus

        init(code: String, label: String, externalRef: String, discount: Double, capacity: Int, status: DispenseOverrideStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.discount = discount
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

        func canMoveTo(_ next: DispenseOverrideStatus) -> Bool {
            switch status {
            case .new:
                return next == DispenseOverrideStatus.running
            case .queued:
                return next == DispenseOverrideStatus.done
            case .running:
                return next == DispenseOverrideStatus.failed
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

        func moveTo(_ next: DispenseOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveExposure() -> Double {
            return (discount * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> DispenseOverride {
            return DispenseOverride(
                code: code,
                label: label,
                externalRef: externalRef,
                discount: discount,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a dispense override in status new.
    static func newDispenseOverride(_ code: String, label: String) -> DispenseOverride {
        return DispenseOverride(
            code: code,
            label: label,
            externalRef: "",
            discount: 0.0,
            capacity: 0,
            status: DispenseOverrideStatus.new
        )
    }
}
