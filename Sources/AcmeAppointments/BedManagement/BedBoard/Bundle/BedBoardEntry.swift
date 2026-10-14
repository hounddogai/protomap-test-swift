import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board entry is in its life cycle.
    enum BedBoardEntryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A bed board entry. Its code is unique within a tenant.
    final class BedBoardEntry {
        var code: String
        var title: String
        var visitMinutes: Int
        var revision: Int
        var score: Double
        var priority: Int
        var refills: Int
        var dosageMg: Double
        var label: String
        var status: BedBoardEntryStatus

        init(code: String, title: String, visitMinutes: Int, revision: Int, score: Double, priority: Int, refills: Int, dosageMg: Double, label: String, status: BedBoardEntryStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.revision = revision
            self.score = score
            self.priority = priority
            self.refills = refills
            self.dosageMg = dosageMg
            self.label = label
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

        func canMoveTo(_ next: BedBoardEntryStatus) -> Bool {
            switch status {
            case .created:
                return next == BedBoardEntryStatus.published || next == BedBoardEntryStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: BedBoardEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func netExposure() -> Double {
            return ((Double(priority) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardEntry {
            return BedBoardEntry(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                revision: revision,
                score: score,
                priority: priority,
                refills: refills,
                dosageMg: dosageMg,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a bed board entry in status created.
    static func newBedBoardEntry(_ code: String, title: String) -> BedBoardEntry {
        return BedBoardEntry(
            code: code,
            title: title,
            visitMinutes: 0,
            revision: 0,
            score: 0.0,
            priority: 0,
            refills: 0,
            dosageMg: 0.0,
            label: "",
            status: BedBoardEntryStatus.created
        )
    }
}
