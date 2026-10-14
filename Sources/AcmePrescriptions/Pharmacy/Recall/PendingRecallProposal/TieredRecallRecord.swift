import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered recall record is in its life cycle.
    enum TieredRecallRecordStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One tiered recall record, with what the planners need to act on it.
    final class TieredRecallRecord {
        var code: String
        var label: String
        var amount: Double
        var windowDays: Int
        var archived: Bool
        var attributes: [String: String]
        var category: String
        var durationMinutes: Int
        var status: TieredRecallRecordStatus

        init(code: String, label: String, amount: Double, windowDays: Int, archived: Bool, attributes: [String: String], category: String, durationMinutes: Int, status: TieredRecallRecordStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.windowDays = windowDays
            self.archived = archived
            self.attributes = attributes
            self.category = category
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: TieredRecallRecordStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == TieredRecallRecordStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRecallRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered recall record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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

        func projectedExposure() -> Double {
            return ((Double(durationMinutes) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> TieredRecallRecord {
            return TieredRecallRecord(
                code: code,
                label: label,
                amount: amount,
                windowDays: windowDays,
                archived: archived,
                attributes: attributes,
                category: category,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered recall record in status created.
    static func newTieredRecallRecord(_ code: String, label: String) -> TieredRecallRecord {
        return TieredRecallRecord(
            code: code,
            label: label,
            amount: 0.0,
            windowDays: 0,
            archived: false,
            attributes: [:],
            category: "",
            durationMinutes: 0,
            status: TieredRecallRecordStatus.created
        )
    }
}
