import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped courier profile is in its life cycle.
    enum CappedCourierProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One capped courier profile, with what the planners need to act on it.
    final class CappedCourierProfile {
        var code: String
        var label: String
        var quantity: Int
        var archived: Bool
        var visitMinutes: Int
        var copay: Double
        var floorValue: Double
        var attributes: [String: String]
        var patientRef: String
        var status: CappedCourierProfileStatus

        init(code: String, label: String, quantity: Int, archived: Bool, visitMinutes: Int, copay: Double, floorValue: Double, attributes: [String: String], patientRef: String, status: CappedCourierProfileStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.archived = archived
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.floorValue = floorValue
            self.attributes = attributes
            self.patientRef = patientRef
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

        func canMoveTo(_ next: CappedCourierProfileStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
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

        func moveTo(_ next: CappedCourierProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped courier profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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

        func projectedLoad() -> Double {
            return ((floorValue - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedCourierProfile {
            return CappedCourierProfile(
                code: code,
                label: label,
                quantity: quantity,
                archived: archived,
                visitMinutes: visitMinutes,
                copay: copay,
                floorValue: floorValue,
                attributes: attributes,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped courier profile in status created.
    static func newCappedCourierProfile(_ code: String, label: String) -> CappedCourierProfile {
        return CappedCourierProfile(
            code: code,
            label: label,
            quantity: 0,
            archived: false,
            visitMinutes: 0,
            copay: 0.0,
            floorValue: 0.0,
            attributes: [:],
            patientRef: "",
            status: CappedCourierProfileStatus.created
        )
    }
}
