import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range claim is in its life cycle.
    enum ReferenceRangeClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A reference range claim as the reference range team keeps it.
    final class ReferenceRangeClaim {
        var code: String
        var label: String
        var copay: Double
        var summary: String
        var contactEmail: String
        var clinicianID: String
        var refills: Int
        var notes: String
        var maximum: Double
        var endsAt: Int
        var facility: String
        var status: ReferenceRangeClaimStatus

        init(code: String, label: String, copay: Double, summary: String, contactEmail: String, clinicianID: String, refills: Int, notes: String, maximum: Double, endsAt: Int, facility: String, status: ReferenceRangeClaimStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.summary = summary
            self.contactEmail = contactEmail
            self.clinicianID = clinicianID
            self.refills = refills
            self.notes = notes
            self.maximum = maximum
            self.endsAt = endsAt
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

        func canMoveTo(_ next: ReferenceRangeClaimStatus) -> Bool {
            switch status {
            case .new:
                return next == ReferenceRangeClaimStatus.running || next == ReferenceRangeClaimStatus.done
            case .queued:
                return next == ReferenceRangeClaimStatus.running || next == ReferenceRangeClaimStatus.done
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ReferenceRangeClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("reference range claim") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((copay + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeClaim {
            return ReferenceRangeClaim(
                code: code,
                label: label,
                copay: copay,
                summary: summary,
                contactEmail: contactEmail,
                clinicianID: clinicianID,
                refills: refills,
                notes: notes,
                maximum: maximum,
                endsAt: endsAt,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a reference range claim in status new.
    static func newReferenceRangeClaim(_ code: String, label: String) -> ReferenceRangeClaim {
        return ReferenceRangeClaim(
            code: code,
            label: label,
            copay: 0.0,
            summary: "",
            contactEmail: "",
            clinicianID: "",
            refills: 0,
            notes: "",
            maximum: 0.0,
            endsAt: 0,
            facility: "",
            status: ReferenceRangeClaimStatus.new
        )
    }
}
