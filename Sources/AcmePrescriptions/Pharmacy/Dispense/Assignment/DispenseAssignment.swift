import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense assignment is in its life cycle.
    enum DispenseAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a dispense assignment and its current status.
    final class DispenseAssignment {
        var code: String
        var label: String
        var refills: Int
        var facility: String
        var durationMinutes: Int
        var version: Int
        var acuity: Int
        var allergy: String
        var attributes: [String: String]
        var locale: String
        var status: DispenseAssignmentStatus

        init(code: String, label: String, refills: Int, facility: String, durationMinutes: Int, version: Int, acuity: Int, allergy: String, attributes: [String: String], locale: String, status: DispenseAssignmentStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.facility = facility
            self.durationMinutes = durationMinutes
            self.version = version
            self.acuity = acuity
            self.allergy = allergy
            self.attributes = attributes
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == DispenseAssignmentStatus.pending || next == DispenseAssignmentStatus.active
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: DispenseAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func projectedTotal() -> Double {
            return (Double(durationMinutes) * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> DispenseAssignment {
            return DispenseAssignment(
                code: code,
                label: label,
                refills: refills,
                facility: facility,
                durationMinutes: durationMinutes,
                version: version,
                acuity: acuity,
                allergy: allergy,
                attributes: attributes,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a dispense assignment in status draft.
    static func newDispenseAssignment(_ code: String, label: String) -> DispenseAssignment {
        return DispenseAssignment(
            code: code,
            label: label,
            refills: 0,
            facility: "",
            durationMinutes: 0,
            version: 0,
            acuity: 0,
            allergy: "",
            attributes: [:],
            locale: "",
            status: DispenseAssignmentStatus.draft
        )
    }
}
