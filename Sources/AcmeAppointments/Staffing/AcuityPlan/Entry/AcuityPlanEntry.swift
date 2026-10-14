import AcmePlatform
import Foundation

extension Staffing {
    /// Where a acuity plan entry is in its life cycle.
    enum AcuityPlanEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A acuity plan entry. Its code is unique within a tenant.
    final class AcuityPlanEntry {
        var code: String
        var name: String
        var version: Int
        var threshold: Double
        var description: String
        var batchSize: Int
        var updatedAt: Int
        var summary: String
        var label: String
        var endsAt: Int
        var status: AcuityPlanEntryStatus

        init(code: String, name: String, version: Int, threshold: Double, description: String, batchSize: Int, updatedAt: Int, summary: String, label: String, endsAt: Int, status: AcuityPlanEntryStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.threshold = threshold
            self.description = description
            self.batchSize = batchSize
            self.updatedAt = updatedAt
            self.summary = summary
            self.label = label
            self.endsAt = endsAt
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

        func canMoveTo(_ next: AcuityPlanEntryStatus) -> Bool {
            switch status {
            case .draft:
                return next == AcuityPlanEntryStatus.pending
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == AcuityPlanEntryStatus.closed
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

        func moveTo(_ next: AcuityPlanEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("acuity plan entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func weightedExposure() -> Double {
            return (Double(updatedAt) * threshold * 100).rounded() / 100
        }

        func copyValue() -> AcuityPlanEntry {
            return AcuityPlanEntry(
                code: code,
                name: name,
                version: version,
                threshold: threshold,
                description: description,
                batchSize: batchSize,
                updatedAt: updatedAt,
                summary: summary,
                label: label,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a acuity plan entry in status draft.
    static func newAcuityPlanEntry(_ code: String, name: String) -> AcuityPlanEntry {
        return AcuityPlanEntry(
            code: code,
            name: name,
            version: 0,
            threshold: 0.0,
            description: "",
            batchSize: 0,
            updatedAt: 0,
            summary: "",
            label: "",
            endsAt: 0,
            status: AcuityPlanEntryStatus.draft
        )
    }
}
