import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered care protocol group is in its life cycle.
    enum TieredCareProtocolGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One tiered care protocol group, with what the planners need to act on it.
    final class TieredCareProtocolGroup {
        var code: String
        var title: String
        var archived: Bool
        var refills: Int
        var label: String
        var name: String
        var margin: Double
        var status: TieredCareProtocolGroupStatus

        init(code: String, title: String, archived: Bool, refills: Int, label: String, name: String, margin: Double, status: TieredCareProtocolGroupStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.refills = refills
            self.label = label
            self.name = name
            self.margin = margin
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

        func canMoveTo(_ next: TieredCareProtocolGroupStatus) -> Bool {
            switch status {
            case .new:
                return next == TieredCareProtocolGroupStatus.done
            case .queued:
                return next == TieredCareProtocolGroupStatus.done || next == TieredCareProtocolGroupStatus.failed
            case .running:
                return next == TieredCareProtocolGroupStatus.failed
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

        func moveTo(_ next: TieredCareProtocolGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered care protocol group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return ((margin - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> TieredCareProtocolGroup {
            return TieredCareProtocolGroup(
                code: code,
                title: title,
                archived: archived,
                refills: refills,
                label: label,
                name: name,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered care protocol group in status new.
    static func newTieredCareProtocolGroup(_ code: String, title: String) -> TieredCareProtocolGroup {
        return TieredCareProtocolGroup(
            code: code,
            title: title,
            archived: false,
            refills: 0,
            label: "",
            name: "",
            margin: 0.0,
            status: TieredCareProtocolGroupStatus.new
        )
    }
}
