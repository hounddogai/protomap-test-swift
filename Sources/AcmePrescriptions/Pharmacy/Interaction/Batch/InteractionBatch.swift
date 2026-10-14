import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction batch is in its life cycle.
    enum InteractionBatchStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A interaction batch as the interaction team keeps it.
    final class InteractionBatch {
        var code: String
        var name: String
        var ward: String
        var summary: String
        var dosageMg: Double
        var payer: String
        var status: InteractionBatchStatus

        init(code: String, name: String, ward: String, summary: String, dosageMg: Double, payer: String, status: InteractionBatchStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.summary = summary
            self.dosageMg = dosageMg
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InteractionBatchStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: InteractionBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> InteractionBatch {
            return InteractionBatch(
                code: code,
                name: name,
                ward: ward,
                summary: summary,
                dosageMg: dosageMg,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a interaction batch in status open.
    static func newInteractionBatch(_ code: String, name: String) -> InteractionBatch {
        return InteractionBatch(
            code: code,
            name: name,
            ward: "",
            summary: "",
            dosageMg: 0.0,
            payer: "",
            status: InteractionBatchStatus.`open`
        )
    }
}
