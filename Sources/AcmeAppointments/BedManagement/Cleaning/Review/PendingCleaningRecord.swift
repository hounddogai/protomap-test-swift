import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending cleaning record is in its life cycle.
    enum PendingCleaningRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One pending cleaning record, with what the planners need to act on it.
    final class PendingCleaningRecord {
        var code: String
        var label: String
        var margin: Double
        var name: String
        var ward: String
        var retries: Int
        var dosageMg: Double
        var channel: String
        var rate: Double
        var tags: [String]
        var status: PendingCleaningRecordStatus

        init(code: String, label: String, margin: Double, name: String, ward: String, retries: Int, dosageMg: Double, channel: String, rate: Double, tags: [String], status: PendingCleaningRecordStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.name = name
            self.ward = ward
            self.retries = retries
            self.dosageMg = dosageMg
            self.channel = channel
            self.rate = rate
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingCleaningRecordStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PendingCleaningRecordStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingCleaningRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending cleaning record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((Double(retries) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> PendingCleaningRecord {
            return PendingCleaningRecord(
                code: code,
                label: label,
                margin: margin,
                name: name,
                ward: ward,
                retries: retries,
                dosageMg: dosageMg,
                channel: channel,
                rate: rate,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a pending cleaning record in status idle.
    static func newPendingCleaningRecord(_ code: String, label: String) -> PendingCleaningRecord {
        return PendingCleaningRecord(
            code: code,
            label: label,
            margin: 0.0,
            name: "",
            ward: "",
            retries: 0,
            dosageMg: 0.0,
            channel: "",
            rate: 0.0,
            tags: [],
            status: PendingCleaningRecordStatus.idle
        )
    }
}
