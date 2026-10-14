import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier agreement is in its life cycle.
    enum CourierAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A courier agreement. Its code is unique within a tenant.
    final class CourierAgreement {
        var code: String
        var name: String
        var unit: String
        var floorValue: Double
        var label: String
        var summary: String
        var expiresAt: Int
        var refills: Int
        var reviewer: String
        var durationMinutes: Int
        var status: CourierAgreementStatus

        init(code: String, name: String, unit: String, floorValue: Double, label: String, summary: String, expiresAt: Int, refills: Int, reviewer: String, durationMinutes: Int, status: CourierAgreementStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.floorValue = floorValue
            self.label = label
            self.summary = summary
            self.expiresAt = expiresAt
            self.refills = refills
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CourierAgreementStatus.rejected || next == CourierAgreementStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: CourierAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func effectiveTotal() -> Double {
            return ((floorValue - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CourierAgreement {
            return CourierAgreement(
                code: code,
                name: name,
                unit: unit,
                floorValue: floorValue,
                label: label,
                summary: summary,
                expiresAt: expiresAt,
                refills: refills,
                reviewer: reviewer,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a courier agreement in status proposed.
    static func newCourierAgreement(_ code: String, name: String) -> CourierAgreement {
        return CourierAgreement(
            code: code,
            name: name,
            unit: "",
            floorValue: 0.0,
            label: "",
            summary: "",
            expiresAt: 0,
            refills: 0,
            reviewer: "",
            durationMinutes: 0,
            status: CourierAgreementStatus.proposed
        )
    }
}
