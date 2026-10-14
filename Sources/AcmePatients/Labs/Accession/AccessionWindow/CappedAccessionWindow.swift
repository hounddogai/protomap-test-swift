import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped accession window is in its life cycle.
    enum CappedAccessionWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped accession window. Its code is unique within a tenant.
    final class CappedAccessionWindow {
        var code: String
        var title: String
        var segment: String
        var externalRef: String
        var dosageMg: Double
        var clinicianID: String
        var endsAt: Int
        var status: CappedAccessionWindowStatus

        init(code: String, title: String, segment: String, externalRef: String, dosageMg: Double, clinicianID: String, endsAt: Int, status: CappedAccessionWindowStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.externalRef = externalRef
            self.dosageMg = dosageMg
            self.clinicianID = clinicianID
            self.endsAt = endsAt
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

        func canMoveTo(_ next: CappedAccessionWindowStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedAccessionWindowStatus.validated || next == CappedAccessionWindowStatus.published
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedAccessionWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped accession window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("capped accession window") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(endsAt) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> CappedAccessionWindow {
            return CappedAccessionWindow(
                code: code,
                title: title,
                segment: segment,
                externalRef: externalRef,
                dosageMg: dosageMg,
                clinicianID: clinicianID,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a capped accession window in status created.
    static func newCappedAccessionWindow(_ code: String, title: String) -> CappedAccessionWindow {
        return CappedAccessionWindow(
            code: code,
            title: title,
            segment: "",
            externalRef: "",
            dosageMg: 0.0,
            clinicianID: "",
            endsAt: 0,
            status: CappedAccessionWindowStatus.created
        )
    }
}
