import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary consent form baseline is in its life cycle.
    enum PrimaryConsentFormBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One primary consent form baseline, with what the planners need to act on it.
    final class PrimaryConsentFormBaseline {
        var code: String
        var label: String
        var visitMinutes: Int
        var contactEmail: String
        var ownerID: String
        var ceiling: Double
        var notes: String
        var source: String
        var graceDays: Int
        var createdAt: Int
        var reviewer: String
        var status: PrimaryConsentFormBaselineStatus

        init(code: String, label: String, visitMinutes: Int, contactEmail: String, ownerID: String, ceiling: Double, notes: String, source: String, graceDays: Int, createdAt: Int, reviewer: String, status: PrimaryConsentFormBaselineStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.contactEmail = contactEmail
            self.ownerID = ownerID
            self.ceiling = ceiling
            self.notes = notes
            self.source = source
            self.graceDays = graceDays
            self.createdAt = createdAt
            self.reviewer = reviewer
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

        func canMoveTo(_ next: PrimaryConsentFormBaselineStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimaryConsentFormBaselineStatus.queued
            case .queued:
                return next == PrimaryConsentFormBaselineStatus.failed
            case .running:
                return next == PrimaryConsentFormBaselineStatus.done
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

        func moveTo(_ next: PrimaryConsentFormBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary consent form baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedVolume() -> Double {
            return ((ceiling - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryConsentFormBaseline {
            return PrimaryConsentFormBaseline(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                contactEmail: contactEmail,
                ownerID: ownerID,
                ceiling: ceiling,
                notes: notes,
                source: source,
                graceDays: graceDays,
                createdAt: createdAt,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary consent form baseline in status new.
    static func newPrimaryConsentFormBaseline(_ code: String, label: String) -> PrimaryConsentFormBaseline {
        return PrimaryConsentFormBaseline(
            code: code,
            label: label,
            visitMinutes: 0,
            contactEmail: "",
            ownerID: "",
            ceiling: 0.0,
            notes: "",
            source: "",
            graceDays: 0,
            createdAt: 0,
            reviewer: "",
            status: PrimaryConsentFormBaselineStatus.new
        )
    }
}
