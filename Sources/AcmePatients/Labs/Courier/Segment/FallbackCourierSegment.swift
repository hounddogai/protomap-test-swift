import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback courier segment is in its life cycle.
    enum FallbackCourierSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One fallback courier segment, with what the planners need to act on it.
    final class FallbackCourierSegment {
        var code: String
        var title: String
        var reviewer: String
        var country: String
        var clinicianID: String
        var margin: Double
        var facility: String
        var checksum: String
        var dosageMg: Double
        var status: FallbackCourierSegmentStatus

        init(code: String, title: String, reviewer: String, country: String, clinicianID: String, margin: Double, facility: String, checksum: String, dosageMg: Double, status: FallbackCourierSegmentStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.country = country
            self.clinicianID = clinicianID
            self.margin = margin
            self.facility = facility
            self.checksum = checksum
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: FallbackCourierSegmentStatus) -> Bool {
            switch status {
            case .created:
                return next == FallbackCourierSegmentStatus.validated || next == FallbackCourierSegmentStatus.retired
            case .validated:
                return next == FallbackCourierSegmentStatus.published || next == FallbackCourierSegmentStatus.retired
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

        func moveTo(_ next: FallbackCourierSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback courier segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback courier segment") \(code)"
        }

        func weightedVolume() -> Double {
            return ((margin - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCourierSegment {
            return FallbackCourierSegment(
                code: code,
                title: title,
                reviewer: reviewer,
                country: country,
                clinicianID: clinicianID,
                margin: margin,
                facility: facility,
                checksum: checksum,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback courier segment in status created.
    static func newFallbackCourierSegment(_ code: String, title: String) -> FallbackCourierSegment {
        return FallbackCourierSegment(
            code: code,
            title: title,
            reviewer: "",
            country: "",
            clinicianID: "",
            margin: 0.0,
            facility: "",
            checksum: "",
            dosageMg: 0.0,
            status: FallbackCourierSegmentStatus.created
        )
    }
}
