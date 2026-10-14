import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted float pool template is in its life cycle.
    enum WeightedFloatPoolTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted float pool template as the float pool team keeps it.
    final class WeightedFloatPoolTemplate {
        var code: String
        var name: String
        var ceiling: Double
        var attributes: [String: String]
        var bed: String
        var pinned: Bool
        var summary: String
        var sequence: Int
        var clinicianID: String
        var description: String
        var encounterID: String
        var status: WeightedFloatPoolTemplateStatus

        init(code: String, name: String, ceiling: Double, attributes: [String: String], bed: String, pinned: Bool, summary: String, sequence: Int, clinicianID: String, description: String, encounterID: String, status: WeightedFloatPoolTemplateStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.attributes = attributes
            self.bed = bed
            self.pinned = pinned
            self.summary = summary
            self.sequence = sequence
            self.clinicianID = clinicianID
            self.description = description
            self.encounterID = encounterID
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

        func canMoveTo(_ next: WeightedFloatPoolTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WeightedFloatPoolTemplateStatus.approved || next == WeightedFloatPoolTemplateStatus.withdrawn
            case .approved:
                return next == WeightedFloatPoolTemplateStatus.rejected
            case .rejected:
                return next == WeightedFloatPoolTemplateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedFloatPoolTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted float pool template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted float pool template") \(code)"
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

        func adjustedTotal() -> Double {
            return ((Double(sequence) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> WeightedFloatPoolTemplate {
            return WeightedFloatPoolTemplate(
                code: code,
                name: name,
                ceiling: ceiling,
                attributes: attributes,
                bed: bed,
                pinned: pinned,
                summary: summary,
                sequence: sequence,
                clinicianID: clinicianID,
                description: description,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted float pool template in status proposed.
    static func newWeightedFloatPoolTemplate(_ code: String, name: String) -> WeightedFloatPoolTemplate {
        return WeightedFloatPoolTemplate(
            code: code,
            name: name,
            ceiling: 0.0,
            attributes: [:],
            bed: "",
            pinned: false,
            summary: "",
            sequence: 0,
            clinicianID: "",
            description: "",
            encounterID: "",
            status: WeightedFloatPoolTemplateStatus.proposed
        )
    }
}
