import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback authorization assignment is in its life cycle.
    enum FallbackAuthorizationAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A fallback authorization assignment. Its code is unique within a tenant.
    final class FallbackAuthorizationAssignment {
        var code: String
        var title: String
        var visitMinutes: Int
        var maximum: Double
        var diagnosisCode: String
        var endsAt: Int
        var dosageMg: Double
        var cost: Double
        var status: FallbackAuthorizationAssignmentStatus

        init(code: String, title: String, visitMinutes: Int, maximum: Double, diagnosisCode: String, endsAt: Int, dosageMg: Double, cost: Double, status: FallbackAuthorizationAssignmentStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.maximum = maximum
            self.diagnosisCode = diagnosisCode
            self.endsAt = endsAt
            self.dosageMg = dosageMg
            self.cost = cost
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

        func canMoveTo(_ next: FallbackAuthorizationAssignmentStatus) -> Bool {
            switch status {
            case .created:
                return next == FallbackAuthorizationAssignmentStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == FallbackAuthorizationAssignmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackAuthorizationAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback authorization assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback authorization assignment") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(endsAt) + cost) * 100).rounded() / 100
        }

        func copyValue() -> FallbackAuthorizationAssignment {
            return FallbackAuthorizationAssignment(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                maximum: maximum,
                diagnosisCode: diagnosisCode,
                endsAt: endsAt,
                dosageMg: dosageMg,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback authorization assignment in status created.
    static func newFallbackAuthorizationAssignment(_ code: String, title: String) -> FallbackAuthorizationAssignment {
        return FallbackAuthorizationAssignment(
            code: code,
            title: title,
            visitMinutes: 0,
            maximum: 0.0,
            diagnosisCode: "",
            endsAt: 0,
            dosageMg: 0.0,
            cost: 0.0,
            status: FallbackAuthorizationAssignmentStatus.created
        )
    }
}
