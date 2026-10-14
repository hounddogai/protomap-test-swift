import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback accession reservation is in its life cycle.
    enum FallbackAccessionReservationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A fallback accession reservation. Its code is unique within a tenant.
    final class FallbackAccessionReservation {
        var code: String
        var title: String
        var ratio: Double
        var budget: Double
        var diagnosisCode: String
        var approved: Bool
        var status: FallbackAccessionReservationStatus

        init(code: String, title: String, ratio: Double, budget: Double, diagnosisCode: String, approved: Bool, status: FallbackAccessionReservationStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.budget = budget
            self.diagnosisCode = diagnosisCode
            self.approved = approved
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

        func canMoveTo(_ next: FallbackAccessionReservationStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == FallbackAccessionReservationStatus.published || next == FallbackAccessionReservationStatus.retired
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

        func moveTo(_ next: FallbackAccessionReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback accession reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netVolume() -> Double {
            return ((budget + ratio) * 100).rounded() / 100
        }

        func copyValue() -> FallbackAccessionReservation {
            return FallbackAccessionReservation(
                code: code,
                title: title,
                ratio: ratio,
                budget: budget,
                diagnosisCode: diagnosisCode,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback accession reservation in status created.
    static func newFallbackAccessionReservation(_ code: String, title: String) -> FallbackAccessionReservation {
        return FallbackAccessionReservation(
            code: code,
            title: title,
            ratio: 0.0,
            budget: 0.0,
            diagnosisCode: "",
            approved: false,
            status: FallbackAccessionReservationStatus.created
        )
    }
}
