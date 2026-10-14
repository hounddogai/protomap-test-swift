import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient claim bundle is in its life cycle.
    enum LenientClaimBundleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a lenient claim bundle and its current status.
    final class LenientClaimBundle {
        var code: String
        var label: String
        var retries: Int
        var visible: Bool
        var ownerID: String
        var attributes: [String: String]
        var acuity: Int
        var diagnosisCode: String
        var visitMinutes: Int
        var dosageMg: Double
        var batchSize: Int
        var status: LenientClaimBundleStatus

        init(code: String, label: String, retries: Int, visible: Bool, ownerID: String, attributes: [String: String], acuity: Int, diagnosisCode: String, visitMinutes: Int, dosageMg: Double, batchSize: Int, status: LenientClaimBundleStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.visible = visible
            self.ownerID = ownerID
            self.attributes = attributes
            self.acuity = acuity
            self.diagnosisCode = diagnosisCode
            self.visitMinutes = visitMinutes
            self.dosageMg = dosageMg
            self.batchSize = batchSize
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

        func canMoveTo(_ next: LenientClaimBundleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: LenientClaimBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient claim bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient claim bundle") \(code)"
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

        func effectiveTotal() -> Double {
            return ((Double(retries) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> LenientClaimBundle {
            return LenientClaimBundle(
                code: code,
                label: label,
                retries: retries,
                visible: visible,
                ownerID: ownerID,
                attributes: attributes,
                acuity: acuity,
                diagnosisCode: diagnosisCode,
                visitMinutes: visitMinutes,
                dosageMg: dosageMg,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient claim bundle in status draft.
    static func newLenientClaimBundle(_ code: String, label: String) -> LenientClaimBundle {
        return LenientClaimBundle(
            code: code,
            label: label,
            retries: 0,
            visible: false,
            ownerID: "",
            attributes: [:],
            acuity: 0,
            diagnosisCode: "",
            visitMinutes: 0,
            dosageMg: 0.0,
            batchSize: 0,
            status: LenientClaimBundleStatus.draft
        )
    }
}
