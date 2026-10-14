import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff mapping is in its life cycle.
    enum HandoffMappingStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A handoff mapping as the handoff team keeps it.
    final class HandoffMapping {
        var code: String
        var title: String
        var expiresAt: Int
        var archived: Bool
        var ratio: Double
        var copay: Double
        var windowDays: Int
        var reviewer: String
        var region: String
        var ownerID: String
        var status: HandoffMappingStatus

        init(code: String, title: String, expiresAt: Int, archived: Bool, ratio: Double, copay: Double, windowDays: Int, reviewer: String, region: String, ownerID: String, status: HandoffMappingStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.archived = archived
            self.ratio = ratio
            self.copay = copay
            self.windowDays = windowDays
            self.reviewer = reviewer
            self.region = region
            self.ownerID = ownerID
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

        func canMoveTo(_ next: HandoffMappingStatus) -> Bool {
            switch status {
            case .new:
                return next == HandoffMappingStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: HandoffMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedLoad() -> Double {
            return (ratio * copay * 100).rounded() / 100
        }

        func copyValue() -> HandoffMapping {
            return HandoffMapping(
                code: code,
                title: title,
                expiresAt: expiresAt,
                archived: archived,
                ratio: ratio,
                copay: copay,
                windowDays: windowDays,
                reviewer: reviewer,
                region: region,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a handoff mapping in status new.
    static func newHandoffMapping(_ code: String, title: String) -> HandoffMapping {
        return HandoffMapping(
            code: code,
            title: title,
            expiresAt: 0,
            archived: false,
            ratio: 0.0,
            copay: 0.0,
            windowDays: 0,
            reviewer: "",
            region: "",
            ownerID: "",
            status: HandoffMappingStatus.new
        )
    }
}
