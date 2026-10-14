import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual language snapshot is in its life cycle.
    enum ManualLanguageSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A manual language snapshot. Its code is unique within a tenant.
    final class ManualLanguageSnapshot {
        var code: String
        var label: String
        var durationMinutes: Int
        var approved: Bool
        var currency: String
        var ward: String
        var specialty: String
        var clinicianID: String
        var tags: [String]
        var ceiling: Double
        var locale: String
        var status: ManualLanguageSnapshotStatus

        init(code: String, label: String, durationMinutes: Int, approved: Bool, currency: String, ward: String, specialty: String, clinicianID: String, tags: [String], ceiling: Double, locale: String, status: ManualLanguageSnapshotStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.approved = approved
            self.currency = currency
            self.ward = ward
            self.specialty = specialty
            self.clinicianID = clinicianID
            self.tags = tags
            self.ceiling = ceiling
            self.locale = locale
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

        func canMoveTo(_ next: ManualLanguageSnapshotStatus) -> Bool {
            switch status {
            case .new:
                return next == ManualLanguageSnapshotStatus.queued || next == ManualLanguageSnapshotStatus.done
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ManualLanguageSnapshotStatus.done || next == ManualLanguageSnapshotStatus.failed
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

        func moveTo(_ next: ManualLanguageSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual language snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedTotal() -> Double {
            return ((ceiling - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ManualLanguageSnapshot {
            return ManualLanguageSnapshot(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                approved: approved,
                currency: currency,
                ward: ward,
                specialty: specialty,
                clinicianID: clinicianID,
                tags: tags,
                ceiling: ceiling,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a manual language snapshot in status new.
    static func newManualLanguageSnapshot(_ code: String, label: String) -> ManualLanguageSnapshot {
        return ManualLanguageSnapshot(
            code: code,
            label: label,
            durationMinutes: 0,
            approved: false,
            currency: "",
            ward: "",
            specialty: "",
            clinicianID: "",
            tags: [],
            ceiling: 0.0,
            locale: "",
            status: ManualLanguageSnapshotStatus.new
        )
    }
}
