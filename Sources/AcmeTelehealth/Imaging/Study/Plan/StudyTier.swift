import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study tier is in its life cycle.
    enum StudyTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A study tier as the study team keeps it.
    final class StudyTier {
        var code: String
        var title: String
        var facility: String
        var summary: String
        var updatedAt: Int
        var region: String
        var patientRef: String
        var ward: String
        var startsAt: Int
        var reviewer: String
        var dosageMg: Double
        var status: StudyTierStatus

        init(code: String, title: String, facility: String, summary: String, updatedAt: Int, region: String, patientRef: String, ward: String, startsAt: Int, reviewer: String, dosageMg: Double, status: StudyTierStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.summary = summary
            self.updatedAt = updatedAt
            self.region = region
            self.patientRef = patientRef
            self.ward = ward
            self.startsAt = startsAt
            self.reviewer = reviewer
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: StudyTierStatus) -> Bool {
            switch status {
            case .new:
                return next == StudyTierStatus.running || next == StudyTierStatus.done
            case .queued:
                return next == StudyTierStatus.running || next == StudyTierStatus.done
            case .running:
                return next == StudyTierStatus.done || next == StudyTierStatus.failed
            case .done:
                return next == StudyTierStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedTotal() -> Double {
            return (Double(updatedAt) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> StudyTier {
            return StudyTier(
                code: code,
                title: title,
                facility: facility,
                summary: summary,
                updatedAt: updatedAt,
                region: region,
                patientRef: patientRef,
                ward: ward,
                startsAt: startsAt,
                reviewer: reviewer,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a study tier in status new.
    static func newStudyTier(_ code: String, title: String) -> StudyTier {
        return StudyTier(
            code: code,
            title: title,
            facility: "",
            summary: "",
            updatedAt: 0,
            region: "",
            patientRef: "",
            ward: "",
            startsAt: 0,
            reviewer: "",
            dosageMg: 0.0,
            status: StudyTierStatus.new
        )
    }
}
