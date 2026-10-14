import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual formulary digest is in its life cycle.
    enum ManualFormularyDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A manual formulary digest. Its code is unique within a tenant.
    final class ManualFormularyDigest {
        var code: String
        var label: String
        var quantity: Int
        var procedureCode: String
        var visitMinutes: Int
        var category: String
        var threshold: Double
        var maximum: Double
        var status: ManualFormularyDigestStatus

        init(code: String, label: String, quantity: Int, procedureCode: String, visitMinutes: Int, category: String, threshold: Double, maximum: Double, status: ManualFormularyDigestStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.procedureCode = procedureCode
            self.visitMinutes = visitMinutes
            self.category = category
            self.threshold = threshold
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualFormularyDigestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ManualFormularyDigestStatus.draining
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ManualFormularyDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual formulary digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("manual formulary digest") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(quantity) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ManualFormularyDigest {
            return ManualFormularyDigest(
                code: code,
                label: label,
                quantity: quantity,
                procedureCode: procedureCode,
                visitMinutes: visitMinutes,
                category: category,
                threshold: threshold,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual formulary digest in status idle.
    static func newManualFormularyDigest(_ code: String, label: String) -> ManualFormularyDigest {
        return ManualFormularyDigest(
            code: code,
            label: label,
            quantity: 0,
            procedureCode: "",
            visitMinutes: 0,
            category: "",
            threshold: 0.0,
            maximum: 0.0,
            status: ManualFormularyDigestStatus.idle
        )
    }
}
