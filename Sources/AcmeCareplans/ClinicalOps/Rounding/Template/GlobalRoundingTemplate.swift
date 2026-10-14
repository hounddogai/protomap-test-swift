import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global rounding template is in its life cycle.
    enum GlobalRoundingTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One global rounding template, with what the planners need to act on it.
    final class GlobalRoundingTemplate {
        var code: String
        var name: String
        var floorValue: Double
        var allergy: String
        var batchSize: Int
        var visible: Bool
        var minimum: Double
        var notes: String
        var acuity: Int
        var retries: Int
        var limit: Int
        var status: GlobalRoundingTemplateStatus

        init(code: String, name: String, floorValue: Double, allergy: String, batchSize: Int, visible: Bool, minimum: Double, notes: String, acuity: Int, retries: Int, limit: Int, status: GlobalRoundingTemplateStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.allergy = allergy
            self.batchSize = batchSize
            self.visible = visible
            self.minimum = minimum
            self.notes = notes
            self.acuity = acuity
            self.retries = retries
            self.limit = limit
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

        func canMoveTo(_ next: GlobalRoundingTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == GlobalRoundingTemplateStatus.rejected || next == GlobalRoundingTemplateStatus.withdrawn
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

        func moveTo(_ next: GlobalRoundingTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global rounding template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global rounding template") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(limit) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> GlobalRoundingTemplate {
            return GlobalRoundingTemplate(
                code: code,
                name: name,
                floorValue: floorValue,
                allergy: allergy,
                batchSize: batchSize,
                visible: visible,
                minimum: minimum,
                notes: notes,
                acuity: acuity,
                retries: retries,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global rounding template in status proposed.
    static func newGlobalRoundingTemplate(_ code: String, name: String) -> GlobalRoundingTemplate {
        return GlobalRoundingTemplate(
            code: code,
            name: name,
            floorValue: 0.0,
            allergy: "",
            batchSize: 0,
            visible: false,
            minimum: 0.0,
            notes: "",
            acuity: 0,
            retries: 0,
            limit: 0,
            status: GlobalRoundingTemplateStatus.proposed
        )
    }
}
