import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier target is in its life cycle.
    enum CourierTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A courier target. Its code is unique within a tenant.
    final class CourierTarget {
        var code: String
        var label: String
        var ward: String
        var copay: Double
        var capacity: Int
        var updatedAt: Int
        var diagnosisCode: String
        var locale: String
        var attributes: [String: String]
        var bed: String
        var status: CourierTargetStatus

        init(code: String, label: String, ward: String, copay: Double, capacity: Int, updatedAt: Int, diagnosisCode: String, locale: String, attributes: [String: String], bed: String, status: CourierTargetStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.copay = copay
            self.capacity = capacity
            self.updatedAt = updatedAt
            self.diagnosisCode = diagnosisCode
            self.locale = locale
            self.attributes = attributes
            self.bed = bed
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

        func canMoveTo(_ next: CourierTargetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CourierTargetStatus.approved || next == CourierTargetStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CourierTargetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedExposure() -> Double {
            return ((Double(updatedAt) - copay) * 100).rounded() / 100
        }

        func copyValue() -> CourierTarget {
            return CourierTarget(
                code: code,
                label: label,
                ward: ward,
                copay: copay,
                capacity: capacity,
                updatedAt: updatedAt,
                diagnosisCode: diagnosisCode,
                locale: locale,
                attributes: attributes,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a courier target in status proposed.
    static func newCourierTarget(_ code: String, label: String) -> CourierTarget {
        return CourierTarget(
            code: code,
            label: label,
            ward: "",
            copay: 0.0,
            capacity: 0,
            updatedAt: 0,
            diagnosisCode: "",
            locale: "",
            attributes: [:],
            bed: "",
            status: CourierTargetStatus.proposed
        )
    }
}
