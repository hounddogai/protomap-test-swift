import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback charge entry is in its life cycle.
    enum FallbackChargeEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A fallback charge entry as the charge team keeps it.
    final class FallbackChargeEntry {
        var code: String
        var title: String
        var endsAt: Int
        var tags: [String]
        var reviewer: String
        var sequence: Int
        var ward: String
        var unit: String
        var procedureCode: String
        var contactEmail: String
        var status: FallbackChargeEntryStatus

        init(code: String, title: String, endsAt: Int, tags: [String], reviewer: String, sequence: Int, ward: String, unit: String, procedureCode: String, contactEmail: String, status: FallbackChargeEntryStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.tags = tags
            self.reviewer = reviewer
            self.sequence = sequence
            self.ward = ward
            self.unit = unit
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: FallbackChargeEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == FallbackChargeEntryStatus.queued || next == FallbackChargeEntryStatus.done
            case .queued:
                return next == FallbackChargeEntryStatus.done || next == FallbackChargeEntryStatus.failed
            case .running:
                return next == FallbackChargeEntryStatus.done || next == FallbackChargeEntryStatus.failed
            case .done:
                return next == FallbackChargeEntryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackChargeEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback charge entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return ((Double(endsAt) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackChargeEntry {
            return FallbackChargeEntry(
                code: code,
                title: title,
                endsAt: endsAt,
                tags: tags,
                reviewer: reviewer,
                sequence: sequence,
                ward: ward,
                unit: unit,
                procedureCode: procedureCode,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback charge entry in status new.
    static func newFallbackChargeEntry(_ code: String, title: String) -> FallbackChargeEntry {
        return FallbackChargeEntry(
            code: code,
            title: title,
            endsAt: 0,
            tags: [],
            reviewer: "",
            sequence: 0,
            ward: "",
            unit: "",
            procedureCode: "",
            contactEmail: "",
            status: FallbackChargeEntryStatus.new
        )
    }
}
