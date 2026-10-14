import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped program notice is in its life cycle.
    enum CappedProgramNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One capped program notice, with what the planners need to act on it.
    final class CappedProgramNotice {
        var code: String
        var name: String
        var dosageMg: Double
        var amount: Double
        var timezone: String
        var segment: String
        var tags: [String]
        var priority: Int
        var expiresAt: Int
        var status: CappedProgramNoticeStatus

        init(code: String, name: String, dosageMg: Double, amount: Double, timezone: String, segment: String, tags: [String], priority: Int, expiresAt: Int, status: CappedProgramNoticeStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.amount = amount
            self.timezone = timezone
            self.segment = segment
            self.tags = tags
            self.priority = priority
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: CappedProgramNoticeStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedProgramNoticeStatus.failed
            case .queued:
                return next == CappedProgramNoticeStatus.done || next == CappedProgramNoticeStatus.failed
            case .running:
                return next == CappedProgramNoticeStatus.done || next == CappedProgramNoticeStatus.failed
            case .done:
                return next == CappedProgramNoticeStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedProgramNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped program notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("capped program notice") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return (amount * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedProgramNotice {
            return CappedProgramNotice(
                code: code,
                name: name,
                dosageMg: dosageMg,
                amount: amount,
                timezone: timezone,
                segment: segment,
                tags: tags,
                priority: priority,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a capped program notice in status new.
    static func newCappedProgramNotice(_ code: String, name: String) -> CappedProgramNotice {
        return CappedProgramNotice(
            code: code,
            name: name,
            dosageMg: 0.0,
            amount: 0.0,
            timezone: "",
            segment: "",
            tags: [],
            priority: 0,
            expiresAt: 0,
            status: CappedProgramNoticeStatus.new
        )
    }
}
