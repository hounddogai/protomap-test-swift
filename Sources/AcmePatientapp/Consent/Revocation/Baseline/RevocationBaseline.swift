import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation baseline is in its life cycle.
    enum RevocationBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A revocation baseline. Its code is unique within a tenant.
    final class RevocationBaseline {
        var code: String
        var label: String
        var patientRef: String
        var diagnosisCode: String
        var category: String
        var amount: Double
        var locale: String
        var ratio: Double
        var limit: Int
        var status: RevocationBaselineStatus

        init(code: String, label: String, patientRef: String, diagnosisCode: String, category: String, amount: Double, locale: String, ratio: Double, limit: Int, status: RevocationBaselineStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.diagnosisCode = diagnosisCode
            self.category = category
            self.amount = amount
            self.locale = locale
            self.ratio = ratio
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RevocationBaselineStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RevocationBaselineStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("revocation baseline") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((amount + ratio) * 100).rounded() / 100
        }

        func copyValue() -> RevocationBaseline {
            return RevocationBaseline(
                code: code,
                label: label,
                patientRef: patientRef,
                diagnosisCode: diagnosisCode,
                category: category,
                amount: amount,
                locale: locale,
                ratio: ratio,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a revocation baseline in status new.
    static func newRevocationBaseline(_ code: String, label: String) -> RevocationBaseline {
        return RevocationBaseline(
            code: code,
            label: label,
            patientRef: "",
            diagnosisCode: "",
            category: "",
            amount: 0.0,
            locale: "",
            ratio: 0.0,
            limit: 0,
            status: RevocationBaselineStatus.new
        )
    }
}
