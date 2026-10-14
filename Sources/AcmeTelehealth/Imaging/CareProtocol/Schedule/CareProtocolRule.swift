import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol rule is in its life cycle.
    enum CareProtocolRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a care protocol rule and its current status.
    final class CareProtocolRule {
        var code: String
        var label: String
        var sequence: Int
        var batchSize: Int
        var margin: Double
        var encounterID: String
        var revision: Int
        var status: CareProtocolRuleStatus

        init(code: String, label: String, sequence: Int, batchSize: Int, margin: Double, encounterID: String, revision: Int, status: CareProtocolRuleStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.batchSize = batchSize
            self.margin = margin
            self.encounterID = encounterID
            self.revision = revision
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

        func canMoveTo(_ next: CareProtocolRuleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == CareProtocolRuleStatus.revoked || next == CareProtocolRuleStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CareProtocolRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return (Double(sequence) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolRule {
            return CareProtocolRule(
                code: code,
                label: label,
                sequence: sequence,
                batchSize: batchSize,
                margin: margin,
                encounterID: encounterID,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care protocol rule in status requested.
    static func newCareProtocolRule(_ code: String, label: String) -> CareProtocolRule {
        return CareProtocolRule(
            code: code,
            label: label,
            sequence: 0,
            batchSize: 0,
            margin: 0.0,
            encounterID: "",
            revision: 0,
            status: CareProtocolRuleStatus.requested
        )
    }
}
