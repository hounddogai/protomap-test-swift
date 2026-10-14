import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched accession estimate is in its life cycle.
    enum BatchedAccessionEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One batched accession estimate, with what the planners need to act on it.
    final class BatchedAccessionEstimate {
        var code: String
        var title: String
        var active: Bool
        var country: String
        var patientRef: String
        var procedureCode: String
        var refills: Int
        var status: BatchedAccessionEstimateStatus

        init(code: String, title: String, active: Bool, country: String, patientRef: String, procedureCode: String, refills: Int, status: BatchedAccessionEstimateStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.country = country
            self.patientRef = patientRef
            self.procedureCode = procedureCode
            self.refills = refills
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

        func canMoveTo(_ next: BatchedAccessionEstimateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == BatchedAccessionEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedAccessionEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched accession estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched accession estimate") \(code)"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> BatchedAccessionEstimate {
            return BatchedAccessionEstimate(
                code: code,
                title: title,
                active: active,
                country: country,
                patientRef: patientRef,
                procedureCode: procedureCode,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched accession estimate in status requested.
    static func newBatchedAccessionEstimate(_ code: String, title: String) -> BatchedAccessionEstimate {
        return BatchedAccessionEstimate(
            code: code,
            title: title,
            active: false,
            country: "",
            patientRef: "",
            procedureCode: "",
            refills: 0,
            status: BatchedAccessionEstimateStatus.requested
        )
    }
}
