import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy accession agreement is in its life cycle.
    enum LegacyAccessionAgreementStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a legacy accession agreement and its current status.
    final class LegacyAccessionAgreement {
        var code: String
        var label: String
        var summary: String
        var priority: Int
        var amount: Double
        var visitMinutes: Int
        var dosageMg: Double
        var visible: Bool
        var discount: Double
        var refills: Int
        var margin: Double
        var status: LegacyAccessionAgreementStatus

        init(code: String, label: String, summary: String, priority: Int, amount: Double, visitMinutes: Int, dosageMg: Double, visible: Bool, discount: Double, refills: Int, margin: Double, status: LegacyAccessionAgreementStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.priority = priority
            self.amount = amount
            self.visitMinutes = visitMinutes
            self.dosageMg = dosageMg
            self.visible = visible
            self.discount = discount
            self.refills = refills
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyAccessionAgreementStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: LegacyAccessionAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy accession agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedVolume() -> Double {
            return (Double(refills) * margin * 100).rounded() / 100
        }

        func copyValue() -> LegacyAccessionAgreement {
            return LegacyAccessionAgreement(
                code: code,
                label: label,
                summary: summary,
                priority: priority,
                amount: amount,
                visitMinutes: visitMinutes,
                dosageMg: dosageMg,
                visible: visible,
                discount: discount,
                refills: refills,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy accession agreement in status planned.
    static func newLegacyAccessionAgreement(_ code: String, label: String) -> LegacyAccessionAgreement {
        return LegacyAccessionAgreement(
            code: code,
            label: label,
            summary: "",
            priority: 0,
            amount: 0.0,
            visitMinutes: 0,
            dosageMg: 0.0,
            visible: false,
            discount: 0.0,
            refills: 0,
            margin: 0.0,
            status: LegacyAccessionAgreementStatus.planned
        )
    }
}
