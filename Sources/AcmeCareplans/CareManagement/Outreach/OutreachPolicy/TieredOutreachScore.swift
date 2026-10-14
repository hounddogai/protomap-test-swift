import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered outreach score is in its life cycle.
    enum TieredOutreachScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a tiered outreach score and its current status.
    final class TieredOutreachScore {
        var code: String
        var name: String
        var version: Int
        var label: String
        var createdAt: Int
        var status: TieredOutreachScoreStatus

        init(code: String, name: String, version: Int, label: String, createdAt: Int, status: TieredOutreachScoreStatus) {
            self.code = code
            self.name = name
            self.version = version
            self.label = label
            self.createdAt = createdAt
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

        func canMoveTo(_ next: TieredOutreachScoreStatus) -> Bool {
            switch status {
            case .new:
                return next == TieredOutreachScoreStatus.queued
            case .queued:
                return next == TieredOutreachScoreStatus.running || next == TieredOutreachScoreStatus.done
            case .running:
                return next == TieredOutreachScoreStatus.done
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

        func moveTo(_ next: TieredOutreachScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered outreach score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("tiered outreach score") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(createdAt) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> TieredOutreachScore {
            return TieredOutreachScore(
                code: code,
                name: name,
                version: version,
                label: label,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered outreach score in status new.
    static func newTieredOutreachScore(_ code: String, name: String) -> TieredOutreachScore {
        return TieredOutreachScore(
            code: code,
            name: name,
            version: 0,
            label: "",
            createdAt: 0,
            status: TieredOutreachScoreStatus.new
        )
    }
}
