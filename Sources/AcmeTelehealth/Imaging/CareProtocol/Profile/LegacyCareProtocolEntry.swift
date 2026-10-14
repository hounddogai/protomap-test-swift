import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy care protocol entry is in its life cycle.
    enum LegacyCareProtocolEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A legacy care protocol entry. Its code is unique within a tenant.
    final class LegacyCareProtocolEntry {
        var code: String
        var label: String
        var phone: String
        var facility: String
        var approved: Bool
        var attributes: [String: String]
        var limit: Int
        var pinned: Bool
        var active: Bool
        var threshold: Double
        var archived: Bool
        var status: LegacyCareProtocolEntryStatus

        init(code: String, label: String, phone: String, facility: String, approved: Bool, attributes: [String: String], limit: Int, pinned: Bool, active: Bool, threshold: Double, archived: Bool, status: LegacyCareProtocolEntryStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.facility = facility
            self.approved = approved
            self.attributes = attributes
            self.limit = limit
            self.pinned = pinned
            self.active = active
            self.threshold = threshold
            self.archived = archived
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

        func canMoveTo(_ next: LegacyCareProtocolEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == LegacyCareProtocolEntryStatus.running || next == LegacyCareProtocolEntryStatus.done
            case .queued:
                return next == LegacyCareProtocolEntryStatus.running || next == LegacyCareProtocolEntryStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == LegacyCareProtocolEntryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyCareProtocolEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy care protocol entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy care protocol entry") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedVolume() -> Double {
            return ((threshold + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCareProtocolEntry {
            return LegacyCareProtocolEntry(
                code: code,
                label: label,
                phone: phone,
                facility: facility,
                approved: approved,
                attributes: attributes,
                limit: limit,
                pinned: pinned,
                active: active,
                threshold: threshold,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a legacy care protocol entry in status new.
    static func newLegacyCareProtocolEntry(_ code: String, label: String) -> LegacyCareProtocolEntry {
        return LegacyCareProtocolEntry(
            code: code,
            label: label,
            phone: "",
            facility: "",
            approved: false,
            attributes: [:],
            limit: 0,
            pinned: false,
            active: false,
            threshold: 0.0,
            archived: false,
            status: LegacyCareProtocolEntryStatus.new
        )
    }
}
