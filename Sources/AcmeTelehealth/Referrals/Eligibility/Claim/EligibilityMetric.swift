import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility metric is in its life cycle.
    enum EligibilityMetricStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One eligibility metric, with what the planners need to act on it.
    final class EligibilityMetric {
        var code: String
        var title: String
        var startsAt: Int
        var dosageMg: Double
        var phone: String
        var patientRef: String
        var source: String
        var checksum: String
        var specialty: String
        var status: EligibilityMetricStatus

        init(code: String, title: String, startsAt: Int, dosageMg: Double, phone: String, patientRef: String, source: String, checksum: String, specialty: String, status: EligibilityMetricStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.dosageMg = dosageMg
            self.phone = phone
            self.patientRef = patientRef
            self.source = source
            self.checksum = checksum
            self.specialty = specialty
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

        func canMoveTo(_ next: EligibilityMetricStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == EligibilityMetricStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("eligibility metric") \(code)"
        }

        func adjustedLoad() -> Double {
            return (Double(startsAt) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> EligibilityMetric {
            return EligibilityMetric(
                code: code,
                title: title,
                startsAt: startsAt,
                dosageMg: dosageMg,
                phone: phone,
                patientRef: patientRef,
                source: source,
                checksum: checksum,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a eligibility metric in status created.
    static func newEligibilityMetric(_ code: String, title: String) -> EligibilityMetric {
        return EligibilityMetric(
            code: code,
            title: title,
            startsAt: 0,
            dosageMg: 0.0,
            phone: "",
            patientRef: "",
            source: "",
            checksum: "",
            specialty: "",
            status: EligibilityMetricStatus.created
        )
    }
}
