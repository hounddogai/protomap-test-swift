import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default remittance target is in its life cycle.
    enum DefaultRemittanceTargetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A default remittance target. Its code is unique within a tenant.
    final class DefaultRemittanceTarget {
        var code: String
        var name: String
        var discount: Double
        var category: String
        var ratio: Double
        var patientRef: String
        var status: DefaultRemittanceTargetStatus

        init(code: String, name: String, discount: Double, category: String, ratio: Double, patientRef: String, status: DefaultRemittanceTargetStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.category = category
            self.ratio = ratio
            self.patientRef = patientRef
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

        func canMoveTo(_ next: DefaultRemittanceTargetStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultRemittanceTargetStatus.queued || next == DefaultRemittanceTargetStatus.done
            case .queued:
                return next == DefaultRemittanceTargetStatus.running || next == DefaultRemittanceTargetStatus.failed
            case .running:
                switch next {
                case .failed:
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

        func moveTo(_ next: DefaultRemittanceTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default remittance target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveVolume() -> Double {
            return ((discount + ratio) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRemittanceTarget {
            return DefaultRemittanceTarget(
                code: code,
                name: name,
                discount: discount,
                category: category,
                ratio: ratio,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a default remittance target in status new.
    static func newDefaultRemittanceTarget(_ code: String, name: String) -> DefaultRemittanceTarget {
        return DefaultRemittanceTarget(
            code: code,
            name: name,
            discount: 0.0,
            category: "",
            ratio: 0.0,
            patientRef: "",
            status: DefaultRemittanceTargetStatus.new
        )
    }
}
