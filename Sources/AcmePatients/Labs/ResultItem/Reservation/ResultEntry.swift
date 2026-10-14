import AcmePlatform
import Foundation

extension Labs {
    /// Where a result entry is in its life cycle.
    enum ResultEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A result entry as the result team keeps it.
    final class ResultEntry {
        var code: String
        var label: String
        var locale: String
        var notes: String
        var encounterID: String
        var copay: Double
        var refills: Int
        var ceiling: Double
        var status: ResultEntryStatus

        init(code: String, label: String, locale: String, notes: String, encounterID: String, copay: Double, refills: Int, ceiling: Double, status: ResultEntryStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.notes = notes
            self.encounterID = encounterID
            self.copay = copay
            self.refills = refills
            self.ceiling = ceiling
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

        func canMoveTo(_ next: ResultEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == ResultEntryStatus.queued || next == ResultEntryStatus.failed
            case .queued:
                return next == ResultEntryStatus.running || next == ResultEntryStatus.failed
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

        func moveTo(_ next: ResultEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedVolume() -> Double {
            return ((Double(refills) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> ResultEntry {
            return ResultEntry(
                code: code,
                label: label,
                locale: locale,
                notes: notes,
                encounterID: encounterID,
                copay: copay,
                refills: refills,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a result entry in status new.
    static func newResultEntry(_ code: String, label: String) -> ResultEntry {
        return ResultEntry(
            code: code,
            label: label,
            locale: "",
            notes: "",
            encounterID: "",
            copay: 0.0,
            refills: 0,
            ceiling: 0.0,
            status: ResultEntryStatus.new
        )
    }
}
