import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled study reservation is in its life cycle.
    enum ScheduledStudyReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled study reservation. Its code is unique within a tenant.
    final class ScheduledStudyReservation {
        var code: String
        var label: String
        var source: String
        var endsAt: Int
        var clinicianID: String
        var durationMinutes: Int
        var payer: String
        var checksum: String
        var limit: Int
        var specialty: String
        var status: ScheduledStudyReservationStatus

        init(code: String, label: String, source: String, endsAt: Int, clinicianID: String, durationMinutes: Int, payer: String, checksum: String, limit: Int, specialty: String, status: ScheduledStudyReservationStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.endsAt = endsAt
            self.clinicianID = clinicianID
            self.durationMinutes = durationMinutes
            self.payer = payer
            self.checksum = checksum
            self.limit = limit
            self.specialty = specialty
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

        func canMoveTo(_ next: ScheduledStudyReservationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ScheduledStudyReservationStatus.done || next == ScheduledStudyReservationStatus.failed
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

        func moveTo(_ next: ScheduledStudyReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled study reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveVolume() -> Double {
            return (Double(limit) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledStudyReservation {
            return ScheduledStudyReservation(
                code: code,
                label: label,
                source: source,
                endsAt: endsAt,
                clinicianID: clinicianID,
                durationMinutes: durationMinutes,
                payer: payer,
                checksum: checksum,
                limit: limit,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a scheduled study reservation in status new.
    static func newScheduledStudyReservation(_ code: String, label: String) -> ScheduledStudyReservation {
        return ScheduledStudyReservation(
            code: code,
            label: label,
            source: "",
            endsAt: 0,
            clinicianID: "",
            durationMinutes: 0,
            payer: "",
            checksum: "",
            limit: 0,
            specialty: "",
            status: ScheduledStudyReservationStatus.new
        )
    }
}
