import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding agreement is in its life cycle.
    enum RoundingAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rounding agreement as the rounding team keeps it.
    final class RoundingAgreement {
        var code: String
        var label: String
        var payer: String
        var dosageMg: Double
        var source: String
        var reviewer: String
        var durationMinutes: Int
        var threshold: Double
        var status: RoundingAgreementStatus

        init(code: String, label: String, payer: String, dosageMg: Double, source: String, reviewer: String, durationMinutes: Int, threshold: Double, status: RoundingAgreementStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.dosageMg = dosageMg
            self.source = source
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.threshold = threshold
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

        func canMoveTo(_ next: RoundingAgreementStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RoundingAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return ((Double(durationMinutes) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> RoundingAgreement {
            return RoundingAgreement(
                code: code,
                label: label,
                payer: payer,
                dosageMg: dosageMg,
                source: source,
                reviewer: reviewer,
                durationMinutes: durationMinutes,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rounding agreement in status draft.
    static func newRoundingAgreement(_ code: String, label: String) -> RoundingAgreement {
        return RoundingAgreement(
            code: code,
            label: label,
            payer: "",
            dosageMg: 0.0,
            source: "",
            reviewer: "",
            durationMinutes: 0,
            threshold: 0.0,
            status: RoundingAgreementStatus.draft
        )
    }
}
