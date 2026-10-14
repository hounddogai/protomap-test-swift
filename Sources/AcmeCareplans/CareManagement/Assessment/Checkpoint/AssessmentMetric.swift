import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment metric is in its life cycle.
    enum AssessmentMetricStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a assessment metric and its current status.
    final class AssessmentMetric {
        var code: String
        var name: String
        var specialty: String
        var weight: Double
        var checksum: String
        var expiresAt: Int
        var externalRef: String
        var facility: String
        var status: AssessmentMetricStatus

        init(code: String, name: String, specialty: String, weight: Double, checksum: String, expiresAt: Int, externalRef: String, facility: String, status: AssessmentMetricStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.weight = weight
            self.checksum = checksum
            self.expiresAt = expiresAt
            self.externalRef = externalRef
            self.facility = facility
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

        func canMoveTo(_ next: AssessmentMetricStatus) -> Bool {
            switch status {
            case .new:
                return next == AssessmentMetricStatus.queued
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == AssessmentMetricStatus.done || next == AssessmentMetricStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AssessmentMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(expiresAt) - weight) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentMetric {
            return AssessmentMetric(
                code: code,
                name: name,
                specialty: specialty,
                weight: weight,
                checksum: checksum,
                expiresAt: expiresAt,
                externalRef: externalRef,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a assessment metric in status new.
    static func newAssessmentMetric(_ code: String, name: String) -> AssessmentMetric {
        return AssessmentMetric(
            code: code,
            name: name,
            specialty: "",
            weight: 0.0,
            checksum: "",
            expiresAt: 0,
            externalRef: "",
            facility: "",
            status: AssessmentMetricStatus.new
        )
    }
}
