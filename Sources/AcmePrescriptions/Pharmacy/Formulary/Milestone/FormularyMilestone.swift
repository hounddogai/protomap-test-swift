import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary milestone is in its life cycle.
    enum FormularyMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A formulary milestone as the formulary team keeps it.
    final class FormularyMilestone {
        var code: String
        var label: String
        var unit: String
        var tags: [String]
        var minimum: Double
        var floorValue: Double
        var visitMinutes: Int
        var batchSize: Int
        var status: FormularyMilestoneStatus

        init(code: String, label: String, unit: String, tags: [String], minimum: Double, floorValue: Double, visitMinutes: Int, batchSize: Int, status: FormularyMilestoneStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.tags = tags
            self.minimum = minimum
            self.floorValue = floorValue
            self.visitMinutes = visitMinutes
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FormularyMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                return next == FormularyMilestoneStatus.revoked || next == FormularyMilestoneStatus.expired
            case .granted:
                return next == FormularyMilestoneStatus.revoked || next == FormularyMilestoneStatus.expired
            case .revoked:
                return next == FormularyMilestoneStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("formulary milestone") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((minimum - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> FormularyMilestone {
            return FormularyMilestone(
                code: code,
                label: label,
                unit: unit,
                tags: tags,
                minimum: minimum,
                floorValue: floorValue,
                visitMinutes: visitMinutes,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a formulary milestone in status requested.
    static func newFormularyMilestone(_ code: String, label: String) -> FormularyMilestone {
        return FormularyMilestone(
            code: code,
            label: label,
            unit: "",
            tags: [],
            minimum: 0.0,
            floorValue: 0.0,
            visitMinutes: 0,
            batchSize: 0,
            status: FormularyMilestoneStatus.requested
        )
    }
}
