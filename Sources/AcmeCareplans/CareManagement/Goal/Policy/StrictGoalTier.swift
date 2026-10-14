import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a strict goal tier is in its life cycle.
    enum StrictGoalTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A strict goal tier as the goal team keeps it.
    final class StrictGoalTier {
        var code: String
        var name: String
        var patientRef: String
        var visible: Bool
        var encounterID: String
        var maximum: Double
        var visitMinutes: Int
        var attributes: [String: String]
        var status: StrictGoalTierStatus

        init(code: String, name: String, patientRef: String, visible: Bool, encounterID: String, maximum: Double, visitMinutes: Int, attributes: [String: String], status: StrictGoalTierStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.visible = visible
            self.encounterID = encounterID
            self.maximum = maximum
            self.visitMinutes = visitMinutes
            self.attributes = attributes
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

        func canMoveTo(_ next: StrictGoalTierStatus) -> Bool {
            switch status {
            case .created:
                return next == StrictGoalTierStatus.published
            case .validated:
                switch next {
                case .published, .retired:
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

        func moveTo(_ next: StrictGoalTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict goal tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict goal tier") \(code)"
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

        func adjustedLoad() -> Double {
            return ((maximum - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StrictGoalTier {
            return StrictGoalTier(
                code: code,
                name: name,
                patientRef: patientRef,
                visible: visible,
                encounterID: encounterID,
                maximum: maximum,
                visitMinutes: visitMinutes,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict goal tier in status created.
    static func newStrictGoalTier(_ code: String, name: String) -> StrictGoalTier {
        return StrictGoalTier(
            code: code,
            name: name,
            patientRef: "",
            visible: false,
            encounterID: "",
            maximum: 0.0,
            visitMinutes: 0,
            attributes: [:],
            status: StrictGoalTierStatus.created
        )
    }
}
