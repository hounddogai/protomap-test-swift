import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy statement threshold is in its life cycle.
    enum LegacyStatementThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A legacy statement threshold. Its code is unique within a tenant.
    final class LegacyStatementThreshold {
        var code: String
        var label: String
        var ceiling: Double
        var createdAt: Int
        var clinicianID: String
        var description: String
        var procedureCode: String
        var expiresAt: Int
        var status: LegacyStatementThresholdStatus

        init(code: String, label: String, ceiling: Double, createdAt: Int, clinicianID: String, description: String, procedureCode: String, expiresAt: Int, status: LegacyStatementThresholdStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.createdAt = createdAt
            self.clinicianID = clinicianID
            self.description = description
            self.procedureCode = procedureCode
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: LegacyStatementThresholdStatus) -> Bool {
            switch status {
            case .created:
                return next == LegacyStatementThresholdStatus.published
            case .validated:
                return next == LegacyStatementThresholdStatus.published || next == LegacyStatementThresholdStatus.retired
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

        func moveTo(_ next: LegacyStatementThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy statement threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netLoad() -> Double {
            return ((Double(expiresAt) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyStatementThreshold {
            return LegacyStatementThreshold(
                code: code,
                label: label,
                ceiling: ceiling,
                createdAt: createdAt,
                clinicianID: clinicianID,
                description: description,
                procedureCode: procedureCode,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy statement threshold in status created.
    static func newLegacyStatementThreshold(_ code: String, label: String) -> LegacyStatementThreshold {
        return LegacyStatementThreshold(
            code: code,
            label: label,
            ceiling: 0.0,
            createdAt: 0,
            clinicianID: "",
            description: "",
            procedureCode: "",
            expiresAt: 0,
            status: LegacyStatementThresholdStatus.created
        )
    }
}
