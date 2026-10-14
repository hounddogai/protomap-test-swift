import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a default program assignment is in its life cycle.
    enum DefaultProgramAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A default program assignment as the program team keeps it.
    final class DefaultProgramAssignment {
        var code: String
        var title: String
        var acuity: Int
        var visible: Bool
        var rate: Double
        var attributes: [String: String]
        var dosageMg: Double
        var refills: Int
        var weight: Double
        var status: DefaultProgramAssignmentStatus

        init(code: String, title: String, acuity: Int, visible: Bool, rate: Double, attributes: [String: String], dosageMg: Double, refills: Int, weight: Double, status: DefaultProgramAssignmentStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.visible = visible
            self.rate = rate
            self.attributes = attributes
            self.dosageMg = dosageMg
            self.refills = refills
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultProgramAssignmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: DefaultProgramAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default program assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
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

        func netValue() -> Double {
            return ((rate + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultProgramAssignment {
            return DefaultProgramAssignment(
                code: code,
                title: title,
                acuity: acuity,
                visible: visible,
                rate: rate,
                attributes: attributes,
                dosageMg: dosageMg,
                refills: refills,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default program assignment in status created.
    static func newDefaultProgramAssignment(_ code: String, title: String) -> DefaultProgramAssignment {
        return DefaultProgramAssignment(
            code: code,
            title: title,
            acuity: 0,
            visible: false,
            rate: 0.0,
            attributes: [:],
            dosageMg: 0.0,
            refills: 0,
            weight: 0.0,
            status: DefaultProgramAssignmentStatus.created
        )
    }
}
