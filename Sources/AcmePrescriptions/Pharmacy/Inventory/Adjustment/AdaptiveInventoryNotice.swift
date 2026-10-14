import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive inventory notice is in its life cycle.
    enum AdaptiveInventoryNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive inventory notice. Its code is unique within a tenant.
    final class AdaptiveInventoryNotice {
        var code: String
        var title: String
        var country: String
        var approved: Bool
        var name: String
        var notes: String
        var batchSize: Int
        var revision: Int
        var status: AdaptiveInventoryNoticeStatus

        init(code: String, title: String, country: String, approved: Bool, name: String, notes: String, batchSize: Int, revision: Int, status: AdaptiveInventoryNoticeStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.approved = approved
            self.name = name
            self.notes = notes
            self.batchSize = batchSize
            self.revision = revision
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

        func canMoveTo(_ next: AdaptiveInventoryNoticeStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveInventoryNoticeStatus.pending || next == AdaptiveInventoryNoticeStatus.active
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == AdaptiveInventoryNoticeStatus.suspended || next == AdaptiveInventoryNoticeStatus.closed
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

        func moveTo(_ next: AdaptiveInventoryNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive inventory notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedTotal() -> Double {
            return ((Double(revision) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveInventoryNotice {
            return AdaptiveInventoryNotice(
                code: code,
                title: title,
                country: country,
                approved: approved,
                name: name,
                notes: notes,
                batchSize: batchSize,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a adaptive inventory notice in status draft.
    static func newAdaptiveInventoryNotice(_ code: String, title: String) -> AdaptiveInventoryNotice {
        return AdaptiveInventoryNotice(
            code: code,
            title: title,
            country: "",
            approved: false,
            name: "",
            notes: "",
            batchSize: 0,
            revision: 0,
            status: AdaptiveInventoryNoticeStatus.draft
        )
    }
}
