import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning manifest is in its life cycle.
    enum CleaningManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a cleaning manifest and its current status.
    final class CleaningManifest {
        var code: String
        var label: String
        var contactEmail: String
        var windowDays: Int
        var allergy: String
        var status: CleaningManifestStatus

        init(code: String, label: String, contactEmail: String, windowDays: Int, allergy: String, status: CleaningManifestStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.windowDays = windowDays
            self.allergy = allergy
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CleaningManifestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CleaningManifestStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CleaningManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> CleaningManifest {
            return CleaningManifest(
                code: code,
                label: label,
                contactEmail: contactEmail,
                windowDays: windowDays,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a cleaning manifest in status draft.
    static func newCleaningManifest(_ code: String, label: String) -> CleaningManifest {
        return CleaningManifest(
            code: code,
            label: label,
            contactEmail: "",
            windowDays: 0,
            allergy: "",
            status: CleaningManifestStatus.draft
        )
    }
}
