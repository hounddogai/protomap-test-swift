import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global alert target is in its life cycle.
    enum GlobalAlertTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a global alert target and its current status.
    final class GlobalAlertTarget {
        var code: String
        var label: String
        var source: String
        var encounterID: String
        var category: String
        var margin: Double
        var sequence: Int
        var score: Double
        var payer: String
        var retries: Int
        var status: GlobalAlertTargetStatus

        init(code: String, label: String, source: String, encounterID: String, category: String, margin: Double, sequence: Int, score: Double, payer: String, retries: Int, status: GlobalAlertTargetStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.encounterID = encounterID
            self.category = category
            self.margin = margin
            self.sequence = sequence
            self.score = score
            self.payer = payer
            self.retries = retries
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

        func canMoveTo(_ next: GlobalAlertTargetStatus) -> Bool {
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
                return next == GlobalAlertTargetStatus.published || next == GlobalAlertTargetStatus.retired
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

        func moveTo(_ next: GlobalAlertTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global alert target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedExposure() -> Double {
            return (Double(retries) * score * 100).rounded() / 100
        }

        func copyValue() -> GlobalAlertTarget {
            return GlobalAlertTarget(
                code: code,
                label: label,
                source: source,
                encounterID: encounterID,
                category: category,
                margin: margin,
                sequence: sequence,
                score: score,
                payer: payer,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a global alert target in status created.
    static func newGlobalAlertTarget(_ code: String, label: String) -> GlobalAlertTarget {
        return GlobalAlertTarget(
            code: code,
            label: label,
            source: "",
            encounterID: "",
            category: "",
            margin: 0.0,
            sequence: 0,
            score: 0.0,
            payer: "",
            retries: 0,
            status: GlobalAlertTargetStatus.created
        )
    }
}
