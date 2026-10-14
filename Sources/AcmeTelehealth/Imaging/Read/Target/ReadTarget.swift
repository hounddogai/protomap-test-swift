import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read target is in its life cycle.
    enum ReadTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A read target. Its code is unique within a tenant.
    final class ReadTarget {
        var code: String
        var label: String
        var copay: Double
        var ownerID: String
        var visitMinutes: Int
        var encounterID: String
        var pinned: Bool
        var limit: Int
        var windowDays: Int
        var status: ReadTargetStatus

        init(code: String, label: String, copay: Double, ownerID: String, visitMinutes: Int, encounterID: String, pinned: Bool, limit: Int, windowDays: Int, status: ReadTargetStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.ownerID = ownerID
            self.visitMinutes = visitMinutes
            self.encounterID = encounterID
            self.pinned = pinned
            self.limit = limit
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReadTargetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ReadTargetStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ReadTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("read target") \(code)"
        }

        func adjustedValue() -> Double {
            return ((copay + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> ReadTarget {
            return ReadTarget(
                code: code,
                label: label,
                copay: copay,
                ownerID: ownerID,
                visitMinutes: visitMinutes,
                encounterID: encounterID,
                pinned: pinned,
                limit: limit,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a read target in status open.
    static func newReadTarget(_ code: String, label: String) -> ReadTarget {
        return ReadTarget(
            code: code,
            label: label,
            copay: 0.0,
            ownerID: "",
            visitMinutes: 0,
            encounterID: "",
            pinned: false,
            limit: 0,
            windowDays: 0,
            status: ReadTargetStatus.`open`
        )
    }
}
