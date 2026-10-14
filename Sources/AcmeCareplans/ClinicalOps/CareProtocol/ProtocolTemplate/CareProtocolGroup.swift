import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol group is in its life cycle.
    enum CareProtocolGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One care protocol group, with what the planners need to act on it.
    final class CareProtocolGroup {
        var code: String
        var label: String
        var encounterID: String
        var locale: String
        var endsAt: Int
        var facility: String
        var status: CareProtocolGroupStatus

        init(code: String, label: String, encounterID: String, locale: String, endsAt: Int, facility: String, status: CareProtocolGroupStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.locale = locale
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

        func canMoveTo(_ next: CareProtocolGroupStatus) -> Bool {
            switch status {
            case .new:
                return next == CareProtocolGroupStatus.running
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CareProtocolGroupStatus.failed
            case .done:
                return next == CareProtocolGroupStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> CareProtocolGroup {
            return CareProtocolGroup(
                code: code,
                label: label,
                encounterID: encounterID,
                locale: locale,
                endsAt: endsAt,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a care protocol group in status new.
    static func newCareProtocolGroup(_ code: String, label: String) -> CareProtocolGroup {
        return CareProtocolGroup(
            code: code,
            label: label,
            encounterID: "",
            locale: "",
            endsAt: 0,
            facility: "",
            status: CareProtocolGroupStatus.new
        )
    }
}
