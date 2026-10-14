import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual formulary policy is in its life cycle.
    enum ManualFormularyPolicyStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A manual formulary policy. Its code is unique within a tenant.
    final class ManualFormularyPolicy {
        var code: String
        var title: String
        var phone: String
        var retries: Int
        var endsAt: Int
        var segment: String
        var dosageMg: Double
        var status: ManualFormularyPolicyStatus

        init(code: String, title: String, phone: String, retries: Int, endsAt: Int, segment: String, dosageMg: Double, status: ManualFormularyPolicyStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.retries = retries
            self.endsAt = endsAt
            self.segment = segment
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: ManualFormularyPolicyStatus) -> Bool {
            switch status {
            case .draft:
                return next == ManualFormularyPolicyStatus.pending
            case .pending:
                return next == ManualFormularyPolicyStatus.active || next == ManualFormularyPolicyStatus.suspended
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

        func moveTo(_ next: ManualFormularyPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual formulary policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("manual formulary policy") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(endsAt) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ManualFormularyPolicy {
            return ManualFormularyPolicy(
                code: code,
                title: title,
                phone: phone,
                retries: retries,
                endsAt: endsAt,
                segment: segment,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual formulary policy in status draft.
    static func newManualFormularyPolicy(_ code: String, title: String) -> ManualFormularyPolicy {
        return ManualFormularyPolicy(
            code: code,
            title: title,
            phone: "",
            retries: 0,
            endsAt: 0,
            segment: "",
            dosageMg: 0.0,
            status: ManualFormularyPolicyStatus.draft
        )
    }
}
