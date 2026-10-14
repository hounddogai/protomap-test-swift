import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol target is in its life cycle.
    enum CareProtocolTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a care protocol target and its current status.
    final class CareProtocolTarget {
        var code: String
        var title: String
        var externalRef: String
        var updatedAt: Int
        var channel: String
        var durationMinutes: Int
        var payer: String
        var category: String
        var status: CareProtocolTargetStatus

        init(code: String, title: String, externalRef: String, updatedAt: Int, channel: String, durationMinutes: Int, payer: String, category: String, status: CareProtocolTargetStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.updatedAt = updatedAt
            self.channel = channel
            self.durationMinutes = durationMinutes
            self.payer = payer
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolTargetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CareProtocolTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("care protocol target") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(durationMinutes) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolTarget {
            return CareProtocolTarget(
                code: code,
                title: title,
                externalRef: externalRef,
                updatedAt: updatedAt,
                channel: channel,
                durationMinutes: durationMinutes,
                payer: payer,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a care protocol target in status planned.
    static func newCareProtocolTarget(_ code: String, title: String) -> CareProtocolTarget {
        return CareProtocolTarget(
            code: code,
            title: title,
            externalRef: "",
            updatedAt: 0,
            channel: "",
            durationMinutes: 0,
            payer: "",
            category: "",
            status: CareProtocolTargetStatus.planned
        )
    }
}
